defmodule RecruitxBackend.FeedbackImageControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.FeedbackImageController

  describe "show" do
    it "should send 404 when file is not to be found" do
      allow File |> to(accept(:exists?, fn(_) -> false end))

      conn = action(:show, %{"id" => "file_name"})

      conn |> should(have_http_status(:not_found))
    end

    it "should send file when file is found" do
      allow File |> to(accept(:exists?, fn(_) -> true end))
      allow Plug.Conn |> to(accept(:send_file, fn(conn, 200, "../uploaded_images/file_name.jpg", 0, :all) -> conn end))
      action(:show, %{"id" => "file_name.jpg"})

      expect Plug.Conn |> to(accepted :send_file)
    end
  end
end
