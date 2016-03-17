defmodule RecruitxBackend.PanelistIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.Repo
  alias Timex.Date

  describe "create" do
    it "should insert valid data in db and return location path in a success response" do
      interview_panelist_params = Map.merge(fields_for(:interview_panelist), %{panelist_experience: 2})

      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist_params}

      expect(response.status) |> to(be(201))
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)
      List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/panelists/#{inserted_panelist.id}"}))
      expect(interview_panelist_params.panelist_login_name) |> to(eql(inserted_panelist.panelist_login_name))
      expect(interview_panelist_params.interview_id) |> to(eql(inserted_panelist.interview_id))
    end

    it "should respond with errors when trying to sign up for the same interview more than once" do
      interview_panelist_params = Map.merge(fields_for(:interview_panelist), %{panelist_experience: 2})

      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist_params}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist_params}

      response |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "signup", reason: "You have already signed up an interview for this candidate"}
      expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end


    it "should respond with errors when trying to sign up for the same candidate's different interview" do
      candidate = create(:candidate)
      interview1 = create(:interview, candidate_id: candidate.id)
      interview2 = create(:interview, candidate_id: candidate.id, start_time: interview1.start_time |> Date.shift(hours: 2))
      interview_panelist1 = create(:interview_panelist, interview_id: interview1.id)
      interview_panelist2 = %{interview_id: interview2.id, panelist_login_name: interview_panelist1.panelist_login_name, panelist_experience: 2}

      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist2}

      response |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "signup", reason: "You have already signed up an interview for this candidate"}
      expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end

    it "should respond with errors when trying to sign up for the interview after maximum(2) signups reached" do
      interview = create(:interview)
      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: 2}))}
      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: 2}))}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: 2}))}

      response |> should(have_http_status(:unprocessable_entity))
      expectedErrorReason = %JSONErrorReason{field_name: "signup_count", reason: "More than 2 signups are not allowed"}
      expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedErrorReason]})))
    end
  end

  describe "delete" do
    it "should delete the interview panelist of a id" do
      interview_panelist = create(:interview_panelist)

      response = delete conn_with_dummy_authorization(), "/panelists/#{interview_panelist.id}"

      response |> should(have_http_status(:no_content))
      expect(response.resp_body) |> to(be(""))
      expect(Repo.get(InterviewPanelist, interview_panelist.id)) |> to(be(nil))
    end
  end

  defp getInterviewPanelistWithName(name) do
    InterviewPanelist |> QueryFilter.filter(%{panelist_login_name: name}, InterviewPanelist) |> Repo.one
  end
end
