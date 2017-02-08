defmodule RecruitxBackend.FeedbackImageController do
  use RecruitxBackend.Web, :controller

  alias Ecto.UUID
  alias RecruitxBackend.Avatar
  alias RecruitxBackend.ErrorView
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.Avatar
  alias Ecto.Multi

  def create(conn, %{"feedback_images" => data, "interview_id" => id, "status_id" => status_id}) do
        result = Interview.update_status(id, String.to_integer(status_id))
        |> Multi.append(store_image_and_generate_changesets(data, id))
        |> Repo.transaction
        {status, result_of_db_transaction} = case result do
          {:ok, _} -> {:ok, "Thanks for submitting feedback!"}
          {:error, _, changeset, _} -> {key, value} = get_key_value(Enum.at(changeset.errors, 0))
                                      {:error, [%JSONErrorReason{field_name: key, reason: value}]}
        end
    conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
  end

  def create(conn, %{"interview_id" => id, "status_id" => status_id}) do
    Interview.update_status(id, String.to_integer(status_id)) |> Repo.transaction
    conn
    |> put_status(:created)
    |> json("Thanks for submitting feedback!")
  end

  def create(conn, %{}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{status_id: ["missing/empty required key"]}})
  end

  def show(conn, %{"id" => id}) do
    feedback_image = FeedbackImage |> Repo.get(id)
    case feedback_image do
      nil -> conn |> put_status(:not_found) |> render(ErrorView, "404.json") |> halt
      _ ->
      response = HTTPotion.get(System.get_env("AWS_DOWNLOAD_URL") <> feedback_image.file_name, [timeout: 60_000])
      case response.status_code do
        200 ->
          conn
          |> put_resp_content_type("image/jpeg")
          |> send_resp(200, response.body)
        _ -> conn |> put_status(:not_found) |> render(ErrorView, "404.json")
      end
    end
  end

  defp store_image_and_generate_changesets(data, id) do
    Enum.reduce(Map.keys(data), Multi.new, fn(key, acc) ->
      {_, random_file_name_suffix} = UUID.load(UUID.bingenerate)
      new_file_name = "interview_#{id}_#{random_file_name_suffix}.jpg"
      plug_to_upload = Map.get(data, key)
      {status, _} = Avatar.store(Map.merge(plug_to_upload, %{filename: new_file_name}))
      case status do
        :ok -> acc |> Multi.insert(:feedback, FeedbackImage.changeset(%FeedbackImage{}, %{file_name: new_file_name, interview_id: id}))
        :error -> acc |> Multi.error(:upload_failed, [%JSONErrorReason{field_name: "upload", reason: "Failed to upload feedback images"}])
      end
    end)
  end

  defp sendResponseBasedOnResult(conn, action, status, response) do
    case {action, status} do
      {:create, :ok} ->
        conn
        |> put_status(:created)
        |> json(response)
      {:create, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%JSONError{errors: response})
    end
  end

  defp get_key_value({key, {value, _args}}), do: {key, value}
  defp get_key_value({key, value}), do: {key, value}

end
