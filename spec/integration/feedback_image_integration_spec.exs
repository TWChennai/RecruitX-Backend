defmodule RecruitxBackend.FeedbackImageIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.FeedbackImageController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Avatar

  import Ecto.Query, only: [from: 2]

  describe "create" do
    it "should update status and feedback images" do
      file_to_upload = %Plug.Upload{path: "image1"}
      allow Avatar |> to(accept(:store, fn(_) -> {:ok} end))
      interview = create(:interview)
      interview_status = create(:interview_status)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => file_to_upload}, "status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(201))
      expect(conn.resp_body) |> to(be("\"Thanks for submitting feedback!\""))
      expect Avatar |> to(accepted :store)
      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
    end

    it "should not update status and feedback images when status has already been updated" do
      interview = create(:interview, interview_status_id: create(:interview_status).id)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "#{create(:interview_status).id}"}

      conn |> should(have_http_status(:unprocessable_entity))
      expected_reason = %JSONErrorReason{field_name: "interview_status", reason: "Feedback has already been entered"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expected_reason]})))
    end

    it "should not update status and feedback images when status_id is invalid" do
      interview = create(:interview)
      expected_reason = %JSONErrorReason{field_name: "interview_status", reason: "does not exist"}

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "0"}

      conn |> should(have_http_status(:unprocessable_entity))
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expected_reason]})))
    end

    it "should not update status and feedback images when interview_id is invalid" do
      interview_status = create(:interview_status)
      file_to_upload = %Plug.Upload{path: "image1"}
      allow Avatar |> to(accept(:store, fn(_) -> {:ok} end))

      conn = post conn_with_dummy_authorization(), "/interviews/0/feedback_images", %{"feedback_images" => %{"0" => file_to_upload}, "status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "interview", reason: "does not exist"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
      expect Avatar |> to(accepted :store)
    end

    it "should not update status and feedback images when file name is invalid" do
      allow Ecto.UUID |> to(accept(:load, fn(_) -> {:ok, "invalid/file/name"} end))

      interview = create(:interview)
      interview_status = create(:interview_status)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "file_name", reason: "has invalid format"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(nil))
      feedback_images = (from f in FeedbackImage, where: f.interview_id == ^interview.id) |> Repo.all
      expect(feedback_images) |> to(be([]))
    end

    it "should create directory when file doesn't exist" do
      allow File |> to(accept(:exists?, fn(_) -> false end))
      allow File |> to(accept(:mkdir!))
      allow File |> to(accept(:cp!, fn("image1", _) -> {:ok} end))
      interview = create(:interview)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "#{create(:interview_status).id}"}

      expect File |> to(accepted :mkdir!)
      conn |> should(have_http_status(201))
      expect(conn.resp_body) |> to(be("\"Thanks for submitting feedback!\""))
    end
  end
end
