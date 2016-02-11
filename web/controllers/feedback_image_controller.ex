defmodule RecruitxBackend.FeedbackImageController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Endpoint
  alias RecruitxBackend.JSONError
  alias Timex.Date
  alias RecruitxBackend.ChangesetInserter

  #plug :scrub_params, "feedback_image" when action in [:create, :update]

  def create(conn, %{"feedback_image" => data, "interview_id" => id}) do
    path = Endpoint.config(:path_to_store_images)
    new_file_name = "interview_#{id}_#{Date.now(:secs)}" <> ".jpg"
    new_file_path = path <> "/" <> new_file_name
    # TODO: Can't this check to create the path be done only once when the app starts up?
    # Otherwise, the same check is happening for each request - which is a performance hit
    if !(File.exists?(path) and File.dir?(path)), do: File.mkdir!(path)
    File.cp!(data.path, new_file_path)

    try do
      feedback_image_changeset = FeedbackImage.changeset(%FeedbackImage{}, %{file_name: new_file_name, interview_id: id})
      {status, feedback_image} = ChangesetInserter.insertChangesets([feedback_image_changeset])
      sendResponseBasedOnResult(conn, :create, status, feedback_image)
    catch {status, error} ->
      sendResponseBasedOnResult(conn, :create, status, error)
    end
  end

  def show(conn, params) do
    path = Endpoint.config(:path_to_store_images)
    if File.exists?(path) and File.dir?(path) do
      # TODO: Hardcoded filename
      send_file(conn, 200, path <> "/trial1.jpg", 0, :all)
    else
      conn |> put_status(200) |> json("file not found")
    end
  end

  def sendResponseBasedOnResult(conn, action, status, response) do
    case {action, status} do
      {:create, :ok} ->
        conn
          |> put_status(:created)
          |> put_resp_header("location", feedback_image_path(conn, :show, response))
          |> json("")
      {:create, _} ->
        conn
          |> put_status(:unprocessable_entity)
          |> json(%JSONError{errors: response})
    end
  end
end
