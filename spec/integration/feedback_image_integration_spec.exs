defmodule RecruitxBackend.FeedbackImageIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.FeedbackImageController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Avatar

  describe "create" do
    it "should update status only if there is no feedback images" do
      interview = insert(:interview)
      interview_status = insert(:interview_status)
      allow Avatar |> to(accept(:store, fn(_) -> {:ok, "file_name"} end))

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(201))
      expect(conn.resp_body) |> to(be("\"Thanks for submitting feedback!\""))
      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(Avatar) |> to_not(accepted :store)
    end

    it "should update status and feedback images" do
      file_to_upload = %Plug.Upload{path: "image1"}
      allow Avatar |> to(accept(:store, fn(_) -> {:ok, "file_name"} end))
      interview = insert(:interview)
      interview_status = insert(:interview_status)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => file_to_upload}, "status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(201))
      expect(conn.resp_body) |> to(be("\"Thanks for submitting feedback!\""))
      expect Avatar |> to(accepted :store)
      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
    end

    it "should not update status and feedback images when status has already been updated" do
      interview = insert(:interview, interview_status_id: insert(:interview_status).id)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "#{insert(:interview_status).id}"}

      conn |> should(have_http_status(:unprocessable_entity))
      expected_reason = %JSONErrorReason{field_name: "interview_status", reason: "Feedback has already been entered"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expected_reason]})))
    end

    it "should not update status and feedback images when status_id is invalid" do
      interview = insert(:interview)
      expected_reason = %JSONErrorReason{field_name: "interview_status", reason: "does not exist"}

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "0"}

      conn |> should(have_http_status(:unprocessable_entity))
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expected_reason]})))
    end

    it "should not update status and feedback images when interview_id is invalid" do
      interview_status = insert(:interview_status)
      file_to_upload = %Plug.Upload{path: "image1"}
      allow Avatar |> to(accept(:store, fn(_) -> {:ok, "file_name"} end))

      conn = post conn_with_dummy_authorization(), "/interviews/0/feedback_images", %{"feedback_images" => %{"0" => file_to_upload}, "status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "interview", reason: "Interview has been deleted"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end

    it "should not update status and feedback images when file name is invalid" do
      allow Ecto.UUID |> to(accept(:load, fn(_) -> {:ok, "invalid/file/name"} end))
      allow Avatar |> to(accept(:store, fn(_) -> {:ok, "invalid/file/name"} end))

      interview = insert(:interview)
      interview_status = insert(:interview_status)

      conn = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => "#{interview_status.id}"}

      conn |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "file_name", reason: "has invalid format"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))

      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(nil))
      feedback_images = (from f in FeedbackImage, where: f.interview_id == ^interview.id) |> Repo.all
      expect(feedback_images) |> to(be([]))
      expect Avatar |> to(accepted :store)
    end

    it "should throw error if status id is not there in request" do
      interview = insert(:interview)

      response = post conn_with_dummy_authorization(), "/interviews/#{interview.id}/feedback_images", %{}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expectedErrorReason =  %{"errors" => %{"status_id" => ["missing/empty required key"]}}
      expect(parsed_response) |> to(be(expectedErrorReason))
      expect(interview.interview_status_id) |> to(be(nil))
    end
  end
end
