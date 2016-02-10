defmodule RecruitxBackend.FeedbackImageController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Endpoint
  alias Timex.Date

  #plug :scrub_params, "feedback_image" when action in [:create, :update]

  def create(conn, %{"feedback_image" => data, "interview_id" => id}) do
    path = Endpoint.config(:path_to_store_images)
    new_file_path = path <> "/interview_#{id}_#{Date.now(:secs)}" <> ".jpg"
    if !(File.exists?(path) and File.dir?(path)), do: File.mkdir!(path)
    File.cp!(data.path, new_file_path)
    conn |> put_status(200) |> json("File uploaded!")
  end

  def show(conn, params) do
    path = Endpoint.config(:path_to_store_images)
    if File.exists?(path) and File.dir?(path) do
      send_file(conn, 200, path <> "/trial1.jpg", 0, :all)
    else
      conn |> put_status(200) |> json("file not found")
    end
  end
end
