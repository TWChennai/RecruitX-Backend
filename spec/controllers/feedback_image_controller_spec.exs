defmodule RecruitxBackend.FeedbackImageControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.FeedbackImageController

  alias RecruitxBackend.FeedbackImage

  describe "show" do
    xit "should send file" do
      allow FeedbackImage |> to(accept(:get_storage_path, fn(_) -> "dummy" end))
      allow HTTPotion |> to(accept(:get, fn(_, _) -> %{status_code: 200, body: ''} end))
      allow File |> to(accept(:write, fn(_, _, []) -> true end))
      allow File |> to(accept(:rm, fn("dummy/file_name") -> true end))
      allow Plug.Conn |> to(accept(:send_file, fn(conn, 200, _, 0, :all) -> conn end))

      action(:show, %{"id" => "file_name"})

      expect Plug.Conn |> to(accepted :send_file)
    end

    xit "should send 404 when file is not found in S3" do
      allow File |> to(accept(:write, fn(_) -> true end))
      allow HTTPotion |> to(accept(:get, fn(_, _) -> %{status_code: 403, body: ''} end))

      response = action(:show, %{"id" => "file_name.jpg"})

      expect HTTPotion |> to(accepted :get)
      conn |> should(have_http_status(404))
    end
  end
end
