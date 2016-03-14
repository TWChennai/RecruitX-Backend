defmodule RecruitxBackend.FeedbackImageControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.FeedbackImageController

  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Repo

  describe "show" do
    it "should send file when file is downloaded from S3" do
      allow Repo |> to(accept(:get, fn(FeedbackImage, 1) -> %{file_name: "test_file"} end))
      allow HTTPotion |> to(accept(:get, fn(_, _) -> %{status_code: 200, body: ''} end))
      allow File |> to(accept(:write, fn(_, _, []) -> true end))
      allow File |> to(accept(:rm, fn(_) -> true end))
      allow Plug.Conn |> to(accept(:send_file, fn(conn, 200, _, 0, :all) -> conn end))

      response = action(:show, %{"id" => 1})

      response |> should(have_http_status(:ok))
    end

    it "should send 404 when feedback image does not exist" do
      allow Repo |> to(accept(:get, fn(1) -> nil end))

      response = action(:show, %{"id" => 1})

      response |> should(have_http_status(404))
    end

    it "should send 404 when feedback image does not exist in S3" do
      allow Repo |> to(accept(:get, fn(1) -> %{file_name: "test_file"} end))
      allow HTTPotion |> to(accept(:get, fn(_, _) -> %{status_code: 400, body: ''} end))

      response = action(:show, %{"id" => 1})

      response |> should(have_http_status(404))
    end
  end
end
