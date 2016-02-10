defmodule RecruitxBackend.FeedbackController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Endpoint

  def create(conn, params) do
    path = Endpoint.config(:path_to_store_images)
    %{"avatar" => data, "interview_id" => id } = params
    if File.exists?(path) and File.dir?(path) do
      File.cp!(data.path, path <> "/trial1.jpg")
    else
      File.mkdir!(path)
      File.cp!(data.path, path <> "/trial1.jpg")
    end
    conn |> put_status(200) |> json("")
  end

  def index(conn, params) do
     path = Endpoint.config(:path_to_store_images)
     if File.exists?(path) and File.dir?(path) do
       send_file(conn, 200, path <> "/trial1.jpg", 0, :all)
     else
      conn |> put_status(200) |> json("file not found")
     end
  end
end
