defmodule RecruitxBackend.FeedbackImageController do
  use RecruitxBackend.Web, :controller

  alias Ecto.UUID
  alias RecruitxBackend.Avatar
  alias RecruitxBackend.ChangesetManipulator
  alias RecruitxBackend.ErrorView
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.Avatar

  def create(conn, %{"feedback_images" => data, "interview_id" => id, "status_id" => status_id}) do
    {status, result_of_db_transaction} = Repo.transaction fn ->
      try do
        Interview.update_status(id, String.to_integer(status_id))
        store_image_and_generate_changesets(data, id) |> ChangesetManipulator.validate_and(Repo.custom_insert)
        "Thanks for submitting feedback!"
      catch {_, result_of_db_transaction} ->
        Repo.rollback(result_of_db_transaction)
      end
    end
    conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
  end

  def create(conn, %{"interview_id" => id, "status_id" => status_id}) do
      Interview.update_status(id, String.to_integer(status_id))
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
    Enum.reduce(Map.keys(data), [], fn(key, acc) ->
      {_, random_file_name_suffix} = UUID.load(UUID.bingenerate)
      new_file_name = "interview_#{id}_#{random_file_name_suffix}.jpg"
      plug_to_upload = Map.get(data, key)
      {status, _} = Avatar.store(Map.merge(plug_to_upload, %{filename: new_file_name}))
      case status do
        :ok -> acc ++ [FeedbackImage.changeset(%FeedbackImage{}, %{file_name: new_file_name, interview_id: id})]
        :error -> throw {:error, [%JSONErrorReason{field_name: "upload", reason: "Failed to upload feedback images"}]}
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
end
