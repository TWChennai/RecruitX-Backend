defmodule RecruitxBackend.PanelistIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint
  @lower_bound "LB"
  @upper_bound "UB"

  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo
  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Role
  alias Timex.Date
  alias Decimal, as: D

  before do: allow ExperienceMatrix |> to(accept(:should_filter_role, fn(_) -> true end))
  let :role, do: create(:role)

  describe "create" do
    it "should insert valid data in db and return location path in a success response" do
      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      interview_panelist_params = fields_for(:interview_panelist, interview_id: interview.id)
      interview_panelist_params = Map.merge(interview_panelist_params, %{panelist_experience: 2, panelist_role: role.name})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist_params}

      expect(response.status) |> to(be(201))
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)
      List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/panelists/#{inserted_panelist.id}"}))
      expect(inserted_panelist.panelist_login_name) |> to(eql(interview_panelist_params.panelist_login_name))
      expect(inserted_panelist.interview_id) |> to(eql(interview_panelist_params.interview_id))
      expect(inserted_panelist.satisfied_criteria) |> to(eql(@lower_bound))
    end

    it "should respond with errors when trying to sign up for the same interview more than once" do
      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      interview_panelist_params = fields_for(:interview_panelist, interview_id: interview.id)

      interview_panelist_params = Map.merge(interview_panelist_params, %{panelist_experience: 2, panelist_role: role.name})

      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist_params}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist_params}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["You have already signed up an interview for this candidate"]}}))
    end


    it "should respond with errors when trying to sign up for the same candidate's different interview" do
      role = create(:role)
      candidate = create(:candidate, role_id: role.id)
      interview1 = create(:interview, candidate_id: candidate.id)
      interview2 = create(:interview, candidate_id: candidate.id, start_time: interview1.start_time |> Date.shift(hours: 2))
      interview_panelist1 = create(:interview_panelist, interview_id: interview1.id)
      interview_panelist2 = %{interview_id: interview2.id, panelist_login_name: interview_panelist1.panelist_login_name, panelist_experience: 2, panelist_role: role.name}

      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => interview_panelist2}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["You have already signed up an interview for this candidate"]}}))
    end

    it "should respond with errors when trying to sign up for the interview after maximum(2) signups reached" do
      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)

      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: 2, panelist_role: role.name}))}
      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: 2, panelist_role: role.name}))}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: 2, panelist_role: role.name}))}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup_count" => ["More than 2 signups are not allowed"]}}))
    end

    it "should accept sign up if experience is above maximum experience with filter" do
      Repo.delete_all ExperienceMatrix

      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix)
      interview_panelist_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_role: role.name, panelist_experience: D.add(experience_matrix.panelist_experience_lower_bound,D.new(1))})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)

      expect(response.status) |> to(be(201))
      expect(inserted_panelist.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should accept sign up if there is no filter for the interview type" do
      Repo.delete_all ExperienceMatrix

      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix)
      interview_panelist_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_role: role.name, panelist_experience: experience_matrix.panelist_experience_lower_bound})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)

      expect(response.status) |> to(be(201))
      expect(inserted_panelist.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should not accept sign up if panelist is not one of the eligible panelists for a interview type" do
      leadership = create(:interview_type)
      interview = create(:interview, interview_type_id: leadership.id)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      allow InterviewType |> to(accept(:get_type_specific_panelists, fn() -> %{leadership.id => ["dummy"]} end))
      interview_panelist_params = %{interview_id: interview.id, panelist_login_name: "test", panelist_experience: Decimal.new(2), panelist_role: role.name}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["You are not eligible to sign up for this interview"]}}))
    end

    it "should accept sign up if panelist is one of the eligible panelists for a interview type" do
      leadership = create(:interview_type)
      interview = create(:interview, interview_type_id: leadership.id)
      allow InterviewType |> to(accept(:get_type_specific_panelists, fn() -> %{leadership.id => ["test"]} end))
      interview_panelist_params = %{interview_id: interview.id, panelist_login_name: "test", panelist_experience: Decimal.new(2), panelist_role: role.name}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}

      expect(response.status) |> to(be(201))
    end

    it "should not accept sign up if interview type is not limited but panelist is not of valid role" do
      leadership = create(:interview_type)
      interview = create(:interview, interview_type_id: leadership.id)
      allow InterviewType |> to(accept(:get_type_specific_panelists, fn() -> %{} end))
      interview_panelist_params = %{interview_id: interview.id, panelist_login_name: "test", panelist_experience: Decimal.new(2), panelist_role: "dummy"}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["You are not eligible to sign up for this interview"]}}))
    end

    it "should not accept sign up if interview type is not limited but panelist is of valid different role" do
      different_role = create(:role)
      leadership = create(:interview_type)
      interview = create(:interview, interview_type_id: leadership.id)
      allow InterviewType |> to(accept(:get_type_specific_panelists, fn() -> %{} end))
      interview_panelist_params = %{interview_id: interview.id, panelist_login_name: "test", panelist_experience: Decimal.new(2), panelist_role: different_role.name}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["You are not eligible to sign up for this interview"]}}))
    end

    it "should accept sign up if the panelist is experienced for the interview type and the candidate" do
      Repo.delete_all ExperienceMatrix

      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id, role_id: role.id)
      interview_panelist_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)

      expect(response.status) |> to(be(201))
      expect(inserted_panelist.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should not accept sign up if the panelist is experienced for the interview type and the candidate of a different_role" do
      Repo.delete_all ExperienceMatrix

      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id)
      interview_panelist_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}
      inserted_panelist = getInterviewPanelistWithName(interview_panelist_params.panelist_login_name)

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"experience_matrix" => ["The panelist does not have enough experience"]}}))
    end

    it "should accept sign up if the panelist is experienced for the interview type and the candidate when already lower_bound is met" do
      Repo.delete_all ExperienceMatrix

      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id, role_id: role.id)
      interview_panelist_1_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      interview_panelist_2_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_1_params)}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_2_params)}
      inserted_panelist_1 = getInterviewPanelistWithName(interview_panelist_1_params.panelist_login_name)
      inserted_panelist_2 = getInterviewPanelistWithName(interview_panelist_2_params.panelist_login_name)

      expect(response.status) |> to(be(201))
      expect(inserted_panelist_1.satisfied_criteria) |> to(be(@lower_bound))
      expect(inserted_panelist_2.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should not accept sign up if the panelist is experienced for the interview type and the candidate when already upper_bound is met" do
      Repo.delete_all ExperienceMatrix

      interview = create(:interview)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id, panelist_experience_lower_bound: D.new(1), candidate_experience_upper_bound: D.new(5), candidate_experience_lower_bound: D.new(-1), role_id: role.id)
      interview_panelist_1_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      interview_panelist_2_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_1_params)}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_2_params)}
      inserted_panelist_1 = getInterviewPanelistWithName(interview_panelist_1_params.panelist_login_name)

      expect(response.status) |> to(be(422))
      expect(inserted_panelist_1.satisfied_criteria) |> to(be(@upper_bound))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"experience_matrix" => ["Panelist with the required eligibility already met"]}}))
    end

    it "should not accept sign up if the panelist is experienced for the interview type but not for the candidate" do
      Repo.delete_all ExperienceMatrix
      Repo.delete_all Candidate

      candidate = create(:candidate, experience: D.new(5))
      interview = create(:interview, candidate_id: candidate.id)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id, candidate_experience_upper_bound: D.sub(candidate.experience, D.new(1)), candidate_experience_lower_bound: D.new(-1), role_id: role.id)
      params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(params)}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"experience_matrix" => ["The panelist does not have enough experience"]}}))
    end

    it "should accept sign up if the panelist is experienced for the interview type but not for the candidate and the role has no filters" do
      allow ExperienceMatrix |> to(accept(:should_filter_role, fn(_) -> false end))
      Repo.delete_all ExperienceMatrix
      Repo.delete_all Candidate
      candidate = create(:candidate, experience: D.new(5))
      interview = create(:interview, candidate_id: candidate.id)
      role_id = (Repo.preload interview, :candidate).candidate.role_id
      role = Role |> Repo.get(role_id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id, candidate_experience_upper_bound: D.sub(candidate.experience, D.new(1)), candidate_experience_lower_bound: D.new(-1))
      params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})

      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(params)}

      expect(response.status) |> to(be(201))
      inserted_panelist = getInterviewPanelistWithName(params.panelist_login_name)
      List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/panelists/#{inserted_panelist.id}"}))
      expect(inserted_panelist.panelist_login_name) |> to(eql(params.panelist_login_name))
      expect(inserted_panelist.interview_id) |> to(eql(params.interview_id))
      expect(inserted_panelist.satisfied_criteria) |> to(eql(@lower_bound))
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
