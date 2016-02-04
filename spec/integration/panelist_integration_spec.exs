defmodule RecruitxBackend.PanelistIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError

  describe "create" do
    it "should insert valid data in db and return location path in a success response" do
      interview_panelist_params = fields_for(:interview_panelist)

      response = post conn(), "/panelists", %{"interview_panelist" => interview_panelist_params}

      expect(response.status) |> to(be(201))
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)
      List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/panelists/#{inserted_panelist.id}"}))
      expect(interview_panelist_params.panelist_login_name) |> to(eql(inserted_panelist.panelist_login_name))
      expect(interview_panelist_params.interview_id) |> to(eql(inserted_panelist.interview_id))
    end

    it "should respond with errors when trying to sign up for the same interview more than once" do
      interview_panelist_params = fields_for(:interview_panelist)

      post conn(), "/panelists", %{"interview_panelist" => interview_panelist_params}
      response = post conn(), "/panelists", %{"interview_panelist" => interview_panelist_params}

      response |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "panelist_login_name", reason: "You have already signed up for this interview"}
      expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end

    it "should respond with errors when trying to sign up for the interview after maximum(2) signups reached" do
      interview = create(:interview)
      post conn(), "/panelists", %{"interview_panelist" => fields_for(:interview_panelist, interview_id: interview.id)}
      post conn(), "/panelists", %{"interview_panelist" => fields_for(:interview_panelist, interview_id: interview.id)}

      response = post conn(), "/panelists", %{"interview_panelist" => fields_for(:interview_panelist, interview_id: interview.id)}

      response |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "signup", reason: "More than 2 signups are not allowed"}
      expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end
  end

  defp getInterviewPanelistWithName(name) do
    Repo.one(InterviewPanelist |> QueryFilter.filter_new(%{panelist_login_name: [name]}))
  end
end
