defmodule RecruitxBackend.FeedbackController do
  use RecruitxBackend.Web, :controller

  def create(conn, params) do
    #TODO: Replacing path by reading from config file
    path = "/Users/subha/uploaded_images"
    %{"avatar" => data} = params
    if File.exists?(path) and File.dir?(path) do
      File.cp!(data.path, path <> "/trial1.jpg")
    else
      File.mkdir!(path)
      File.cp!(data.path, path <> "/trial1.jpg")
    end
    conn |> put_status(200) |> json("")
  end

  def index(conn, params) do
     path = "/Users/subha/uploaded_images"
     send_file(conn, 200, path <> "/trial1.jpg", 0, :all)
  end
end
