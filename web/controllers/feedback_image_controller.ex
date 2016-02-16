defmodule RecruitxBackend.FeedbackImageController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Endpoint
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.ChangesetManipulator
  alias Ecto.UUID

  #plug :scrub_params, "feedback_image" when action in [:create, :update]

  def create(conn, %{"feedback_images" => data, "interview_id" => id, "status_id" => status_id}) do
    {status, result_of_db_transaction} = Repo.transaction fn ->
      try do
        Interview.update_status(id, String.to_integer(status_id))
        ChangesetManipulator.insertChangesets(store_image_and_generate_changesets(get_storage_path, data, id))
        "Thanks for submitting feedback!"
      catch {_, result_of_db_transaction} ->
        Repo.rollback(result_of_db_transaction)
      end
    end
    conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
  end

  def show(conn, params) do
    file_path = get_storage_path <> "/" <> params["id"]
    case File.exists?(file_path) do
      true -> conn |> send_file(200, file_path, 0, :all)
      _ -> conn |> put_status(:not_found) |> render(RecruitxBackend.ErrorView, "404.json")
    end
  end

  defp store_image_and_generate_changesets(path, data, id) do
    Enum.reduce(Map.keys(data), [], fn(key, acc) ->
      {_, random_file_name_suffix} = UUID.load(UUID.bingenerate)
      new_file_name = "interview_#{id}_#{random_file_name_suffix}.jpg"
      new_file_path = path <> "/" <> new_file_name
      File.cp!(Map.get(data, key).path, new_file_path)
      acc ++ [FeedbackImage.changeset(%FeedbackImage{}, %{file_name: new_file_name, interview_id: id})]
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

  defp get_storage_path do
    path = Endpoint.config(:path_to_store_images)
    # TODO: Can't this check to create the path be done only once when the app starts up?
    # Otherwise, the same check is happening for each request - which is a performance hit
    if !File.exists?(path) || !File.dir?(path), do: File.mkdir!(path)
    path
  end
end
