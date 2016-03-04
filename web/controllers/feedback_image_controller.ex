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
        ChangesetManipulator.insertChangesets(store_image_and_generate_changesets(FeedbackImage.get_storage_path, data, id))
        "Thanks for submitting feedback!"
      catch {_, result_of_db_transaction} ->
        Repo.rollback(result_of_db_transaction)
      end
    end
    conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
  end

  def show(conn, params) do
    {_, random_file_name_suffix} = UUID.load(UUID.bingenerate)
    file_path = FeedbackImage.get_storage_path <> "/" <> random_file_name_suffix
    response = HTTPotion.get(System.get_env("AWS_DOWNLOAD_URL") <> params["id"], [timeout: 60_000])
    case response.status_code do
      200 ->
        File.write(file_path, response.body,[])
        conn = conn |> send_file(200, file_path, 0, :all)
        File.rm file_path
        conn
      _ -> conn |> put_status(:not_found) |> render(ErrorView, "404.json")
    end
  end

  defp store_image_and_generate_changesets(_path, data, id) do
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
