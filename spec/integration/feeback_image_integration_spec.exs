defmodule RecruitxBackend.FeedbackImageIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.FeedbackImageController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason

  describe "create" do
    it "should update status and feedback images" do
      allow File |> to(accept(:exists?, fn(_) -> true end))
      allow File |> to(accept(:cp!, fn("image1", _) -> {:ok} end))
      interview = create(:interview)
      interview_status = create(:interview_status)

      conn = post conn(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => interview_status.id}

      conn |> should(have_http_status(201))
      expect(conn.resp_body) |> to(be("\"Thanks for submitting feedback!\""))
      expect File |> to(accepted :cp!)
      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
    end

    it "should not update status and feedback images when status has already been updated" do
      allow File |> to(accept(:exists?, fn(_) -> true end))
      interview = create(:interview, interview_status_id: create(:interview_status).id)

      conn = post conn(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => create(:interview_status).id}

      conn |> should(have_http_status(:unprocessable_entity))
      expected_reason = %JSONErrorReason{field_name: "interview_status", reason: "Feedback has already been entered"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expected_reason]})))
    end

    it "should not update status and feedback images when status_id is invalid" do
      allow File |> to(accept(:exists?, fn(_) -> true end))
      interview = create(:interview)
      expected_reason = %JSONErrorReason{field_name: "interview_status", reason: "does not exist"}

      conn = post conn(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => 0}

      conn |> should(have_http_status(:unprocessable_entity))
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expected_reason]})))
    end

    it "should not update status and feedback images when interview_id is invalid" do
      allow File |> to(accept(:exists?, fn(_) -> true end))
      interview_status = create(:interview_status)
      allow File |> to(accept(:cp!, fn("image1", _) -> {:ok} end))

      conn = post conn(), "/interviews/0/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => interview_status.id}

      conn |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "interview", reason: "does not exist"}
      expect(conn.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end

    it "should create directory when file doesn't exist" do
      allow File |> to(accept(:exists?, fn(_) -> false end))
      allow File |> to(accept(:mkdir!))
      allow File |> to(accept(:cp!, fn("image1", _) -> {:ok} end))
      interview = create(:interview)

      conn = post conn(), "/interviews/#{interview.id}/feedback_images", %{"feedback_images" => %{"0" => %Plug.Upload{path: "image1"}}, "status_id" => create(:interview_status).id}

      expect File |> to(accepted :mkdir!)
      conn |> should(have_http_status(201))
      expect(conn.resp_body) |> to(be("\"Thanks for submitting feedback!\""))
    end
  end
end
