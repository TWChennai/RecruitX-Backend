defmodule RecruitxBackend.FeedbackImageController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Endpoint
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias Timex.Date
  alias RecruitxBackend.ChangesetInserter

  #plug :scrub_params, "feedback_image" when action in [:create, :update]

  def create(conn, %{"feedback_images" => data, "interview_id" => id, "status_id" => status_id}) do
    path = Endpoint.config(:path_to_store_images)
    # TODO: Can't this check to create the path be done only once when the app starts up?
    # Otherwise, the same check is happening for each request - which is a performance hit
    if !(File.exists?(path) and File.dir?(path)), do: File.mkdir!(path)
    try do
      Interview.update_status(id, status_id)
      ChangesetInserter.insertChangesets(store_image_and_generate_changesets(path, data, id))
      sendResponseBasedOnResult(conn, :create, :ok, "Files uploaded")
    catch {status, error} ->
      sendResponseBasedOnResult(conn, :create, status, error)
    end
  end

  def show(conn, params) do
    file_name = params["id"]
    path = Endpoint.config(:path_to_store_images)
    file_path = path <> "/" <> file_name
    if File.exists?(file_path) do
      send_file(conn, 200, file_path, 0, :all)
    else
      render(conn |> put_status(:not_found), RecruitxBackend.ErrorView, "404.json")
    end
  end

  defp store_image_and_generate_changesets(path, data, id) do
    Enum.reduce(Map.keys(data), [], fn(key, acc) ->
      # TODO: Why do we need a random for the runtime code?
      new_file_name = "interview_#{id}_#{:rand.uniform(Date.now(:secs))}.jpg"
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
end
