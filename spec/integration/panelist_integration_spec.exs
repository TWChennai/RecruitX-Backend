defmodule RecruitxBackend.PanelistIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint
  @lower_bound "LB"
  @upper_bound "UB"

  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.Repo
  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Role
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.TeamDetailsUpdate
  alias Timex.Date
  alias Decimal, as: D

  let :jigsaw_result, do: %{body: "{\"employeeId\":\"17991\",\"role\":{\"name\":\"Dev\"},\"project\":{\"name\":\"Recruitx\"}}", status_code: 200}
  let :role, do: create(:role)

  before do: allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result end))
  before do: allow ExperienceMatrix |> to(accept(:should_filter_role, fn(_) -> true end))
  before do: allow TeamDetailsUpdate |> to(accept(:update, fn() -> true end))
  before do: allow TeamDetailsUpdate |> to(accept(:update_in_background, fn(_, _) -> true end))

  describe "index" do
    before do: Repo.delete_all(Interview)
    it "should get weekly signups by default" do
      team = create(:team, %{name: "test_team"})
      role = create(:role, %{name: "test_role"})
      interview_within_range = create(:interview, %{start_time: Date.now})
      create(:interview_panelist, %{panelist_login_name: "test", team_id: team.id,
        interview_id: interview_within_range.id})
      create(:panelist_details, %{panelist_login_name: "test", role_id: role.id})

      response = get conn_with_dummy_authorization(), "/panelists"

      response |> should(be_successful)
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be([%{
        "team" => "test_team",
        "signups" => [%{"role" => "test_role", "names" => ["test"],"count" => 1}],
        "count" => 1}]))
    end

    it "should get monthly signups" do
      team = create(:team, %{name: "test_team", active: true})
      team1 = create(:team, %{name: "test_team1", active: true})
      role = create(:role, %{name: "test_role"})
      role1 = create(:role, %{name: "test_role1"})
      interview_within_range1 = create(:interview, %{start_time: Date.now |> Date.beginning_of_month})
      interview_within_range2 = create(:interview, %{start_time: Date.now |> Date.end_of_month})
      interview_within_range3 = create(:interview, %{start_time: Date.now})
      interview_out_of_range = create(:interview, %{start_time: Date.now() |> Date.beginning_of_month |>  Date.shift(days: -1)})

      create(:interview_panelist, %{panelist_login_name: "test", team_id: team.id,
      interview_id: interview_within_range1.id})
      create(:interview_panelist, %{panelist_login_name: "test1", team_id: team.id,
      interview_id: interview_within_range2.id})
      create(:interview_panelist, %{panelist_login_name: "test2", team_id: team1.id,
      interview_id: interview_within_range3.id})
      create(:interview_panelist, %{panelist_login_name: "test", team_id: team.id,
      interview_id: interview_out_of_range.id})

      create(:panelist_details, %{panelist_login_name: "test", role_id: role.id})
      create(:panelist_details, %{panelist_login_name: "test1", role_id: role1.id})
      create(:panelist_details, %{panelist_login_name: "test2", role_id: role1.id})

      response = get conn_with_dummy_authorization(), "/panelists",
      %{"monthly" => "true"}

      response |> should(be_successful)
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response)
      |> to(be([%{
                "team" => "test_team",
                "signups" => [%{"role" => "test_role", "names" => ["test"],"count" => 1},
                              %{"role" => "test_role1", "names" => ["test1"],"count" => 1}],
                "count" => 2},
                %{
                  "team" => "test_team1",
                  "signups" => [%{"role" => "test_role1", "names" => ["test2"],"count" => 1}],
                  "count" => 1
                }]))
    end
  end

  describe "create" do
    it "should insert valid interveiw panelist details in db and return location path in a success response" do
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

    it "should insert valid slot panelist details in db and return location path in a success response" do
      role = create(:role)
      slot = create(:slot, role_id: role.id)
      slot_panelist_params = fields_for(:slot_panelist, slot_id: slot.id)
      slot_panelist_params = Map.merge(slot_panelist_params, %{panelist_experience: 2, panelist_role: role.name})
      response = post conn_with_dummy_authorization(), "/panelists", %{"slot_panelist" => slot_panelist_params}

      expect(response.status) |> to(be(201))
      inserted_slot = getSlotPanelistWithName(slot_panelist_params.panelist_login_name)
      List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/panelists/#{inserted_slot.id}"}))
      expect(inserted_slot.panelist_login_name) |> to(eql(slot_panelist_params.panelist_login_name))
      expect(inserted_slot.slot_id) |> to(eql(slot_panelist_params.slot_id))
      expect(inserted_slot.satisfied_criteria) |> to(eql(@lower_bound))
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

    it "should respond with errors when trying to sign up for the same slot more than once" do
      role = create(:role)
      slot = create(:slot, role_id: role.id)
      slot_panelist_params = fields_for(:slot_panelist, slot_id: slot.id)
      slot_panelist_params = Map.merge(slot_panelist_params, %{panelist_experience: 2, panelist_role: role.name})

      post conn_with_dummy_authorization(), "/panelists", %{"slot_panelist" => slot_panelist_params}
      response = post conn_with_dummy_authorization(), "/panelists", %{"slot_panelist" => slot_panelist_params}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["You are already signed up for another interview within 2 hours"]}}))
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

    it "should respond with errors when trying to sign up for the tech2 interview before satisfing the tech1 interview" do
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech2_round = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = create(:candidate)
      tech1_interview = create(:interview, candidate_id: candidate.id, interview_type_id: tech1_round.id)
      tech2_interview = create(:interview, candidate_id: candidate.id, interview_type_id: tech2_round.id)
      role = Role |> Repo.get(candidate.role_id)

      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: tech1_interview.id), %{panelist_experience: 2, panelist_role: role.name}))}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: tech2_interview.id), %{panelist_experience: 2, panelist_role: role.name}))}

      response |> should(have_http_status(:unprocessable_entity))
      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"errors" => %{"signup" => ["Please signup for Tech1 round as signup is pending for that"]}}))
    end

    it "should accept when trying to sign up for the tech2 interview after satisfing the tech1 interview" do
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech2_round = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = create(:candidate)
      tech1_interview = create(:interview, candidate_id: candidate.id, interview_type_id: tech1_round.id)
      tech2_interview = create(:interview, candidate_id: candidate.id, interview_type_id: tech2_round.id)
      role = Role |> Repo.get(candidate.role_id)

      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: tech1_interview.id), %{panelist_experience: 2, panelist_role: role.name}))}
      post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: tech1_interview.id), %{panelist_experience: 2, panelist_role: role.name}))}
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist, interview_id: tech2_interview.id), %{panelist_experience: 2, panelist_role: role.name}))}

      response |> should(have_http_status(:created))
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

      role = create(:role)
      candidate = create(:candidate, role_id: role.id)
      interview = create(:interview, candidate_id: candidate.id)
      experience_matrix = create(:experience_matrix, interview_type_id: interview.interview_type_id, panelist_experience_lower_bound: Decimal.new(1))
      _experience_matrix_for_same_role = create(:experience_matrix, interview_type_id: interview.interview_type_id, role_id: role.id, panelist_experience_lower_bound: Decimal.new(2))
      interview_panelist_params = Map.merge(fields_for(:interview_panelist, interview_id: interview.id), %{panelist_experience: experience_matrix.panelist_experience_lower_bound, panelist_role: role.name})
      response = post conn_with_dummy_authorization(), "/panelists", %{"interview_panelist" => convertKeysFromAtomsToStrings(interview_panelist_params)}

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

  describe "delete interview panelist" do
    it "should delete the interview panelist of a id" do
      interview_panelist = create(:interview_panelist)

      response = delete conn_with_dummy_authorization(), "/panelists/#{interview_panelist.id}"

      response |> should(have_http_status(:no_content))
      expect(response.resp_body) |> to(be(""))
      expect(Repo.get(InterviewPanelist, interview_panelist.id)) |> to(be(nil))
    end
  end

  describe "delete slot panelist" do
    it "should delete the slot panelist of a id" do
      slot_panelist = create(:slot_panelist)

      response = delete conn_with_dummy_authorization(), "/decline_slot/#{slot_panelist.id}"

      response |> should(have_http_status(:no_content))
      expect(response.resp_body) |> to(be(""))
      expect(Repo.get(SlotPanelist, slot_panelist.id)) |> to(be(nil))
    end
  end

  describe "remove action" do
    let :candidate, do: create(:candidate)
    let :interview, do: create(:interview, candidate_id: candidate.id)
    let :interview_panelist, do: create(:interview_panelist, interview_id: interview.id)


    it "should send email to signed up panelist" do
      email = %{subject: "[RecruitX] Change in interview panel", to: interview_panelist.panelist_login_name <> System.get_env("EMAIL_POSTFIX") |> String.split, html_body: "html content"}
      allow Swoosh.Templates |> to(accept(:panelist_removal_notification, fn(_, _, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      response = delete conn_with_dummy_authorization(), "/remove_panelists/#{interview_panelist.id}"

      response |> should(have_http_status(:no_content))
      expect(response.resp_body) |> to(be(""))
      expect(Repo.get(InterviewPanelist, interview_panelist.id)) |> to(be(nil))
      expect Swoosh.Templates |> to(accepted :panelist_removal_notification)
      expect MailHelper |> to(accepted :deliver, [email])
    end

    it "should send email to other panelist who signed up" do
      interview_panelist2 = create(:interview_panelist, interview_id: interview.id)
      email = %{subject: "[RecruitX] Change in interview panel", to: interview_panelist2.panelist_login_name <> System.get_env("EMAIL_POSTFIX") |> String.split, html_body: "html content"}

      allow Swoosh.Templates |> to(accept(:panelist_removal_notification, fn(_, _, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      response = delete conn_with_dummy_authorization(), "/remove_panelists/#{interview_panelist.id}"

      response |> should(have_http_status(:no_content))
      expect(response.resp_body) |> to(be(""))
      expect(Repo.get(InterviewPanelist, interview_panelist.id)) |> to(be(nil))
      expect Swoosh.Templates |> to(accepted :panelist_removal_notification)
      expect MailHelper |> to(accepted :deliver, [email])
    end
  end

  defp getInterviewPanelistWithName(name) do
    InterviewPanelist |> QueryFilter.filter(%{panelist_login_name: name}, InterviewPanelist) |> Repo.one
  end

  defp getSlotPanelistWithName(name) do
    SlotPanelist |> QueryFilter.filter(%{panelist_login_name: name}, SlotPanelist) |> Repo.one
  end
end
