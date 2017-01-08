defmodule RecruitxBackend.InterviewIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Slot
  alias RecruitxBackend.TimexHelper

  import Ecto.Query, only: [preload: 2]

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  describe "index" do
    before do: Repo.delete_all(Candidate)

    it "should return empty when panelist has taken no interviews" do
      response = get conn_with_dummy_authorization(), "/panelists/recruitx/interviews?page"

      expect(response.status) |> to(be(200))
      expect(response.assigns.interviews.entries) |> to(be([]))
    end

    it "should return slot when page is nil and panelist has signedup a slot" do
      slot_panelist = create(:slot_panelist, panelist_login_name: "recruitx")
      slot = Slot
              |> preload([:slot_panelists])
              |> Repo.get(slot_panelist.slot_id)

      response = get conn_with_dummy_authorization(), "/panelists/recruitx/interviews?page"

      expect(response.status) |> to(be(200))
      expect(response.assigns.interviews.entries) |> to(be([slot]))
    end

    it "should return slot when page is 1 and panelist has signedup a slot" do
      slot_panelist = create(:slot_panelist, panelist_login_name: "recruitx")
      slot = Slot
              |> preload([:slot_panelists])
              |> Repo.get(slot_panelist.slot_id)

      response = get conn_with_dummy_authorization(), "/panelists/recruitx/interviews?page=1"

      expect(response.status) |> to(be(200))
      expect(response.assigns.interviews.entries) |> to(be([slot]))
    end

    it "should not return slot when page is greater than 1" do
      create(:slot_panelist, panelist_login_name: "recruitx")

      response = get conn_with_dummy_authorization(), "/panelists/recruitx/interviews?page=2"

      expect(response.status) |> to(be(200))
      expect(response.assigns.interviews.entries) |> to(be([]))
    end

    it "should return list of interviews that the panelist has taken" do
      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id)
      create(:candidate_skill, candidate_id: candidate.id)
      create(:interview_panelist, panelist_login_name: "test", interview_id: interview.id)

      response = get conn_with_dummy_authorization(), "/panelists/test/interviews?page"

      expect(response.status) |> to(be(200))
      [result_interview] = response.assigns.interviews.entries
      expect(compare_fields(result_interview, interview, [:id, :start_time])) |> to(be_true)
      expect(compare_fields(result_interview.candidate, Repo.get(Candidate, interview.candidate_id), [:name, :experience, :role_id, :other_skills])) |> to(be_true)
    end

    it "should return list of interviews and slots that the panelist has taken" do
      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id)
      slot = create(:slot)
      create(:candidate_skill, candidate_id: candidate.id)
      create(:interview_panelist, panelist_login_name: "test", interview_id: interview.id)
      create(:slot_panelist, panelist_login_name: "test", slot_id: slot.id)

      response = get conn_with_dummy_authorization(), "/panelists/test/interviews?page"
      [result_slot, result_interview] = response.assigns.interviews.entries

      expect(response.status) |> to(be(200))
      expect(compare_fields(result_interview, interview, [:id, :start_time])) |> to(be_true)
      expect(compare_fields(result_interview.candidate, Repo.get(Candidate, interview.candidate_id), [:name, :experience, :role_id, :other_skills])) |> to(be_true)
      expect(compare_fields(result_slot, slot, [:id, :role_id, :interview_type_id])) |> to(be_true)
      expect(Enum.at(result_slot.slot_panelists, 0).panelist_login_name) |> to(be("test"))
    end

    it "should return list of interviews that the panelist has taken with the last interview statuts if pipeline is closed and all rounds are over" do
      Repo.delete_all Candidate
      Repo.delete_all Slot
      Repo.delete_all InterviewType
      interview_panelist = create(:interview_panelist, panelist_login_name: "test")
      interview = Interview |> Repo.get(interview_panelist.interview_id)
      candidate = Candidate |> Repo.get(interview.candidate_id)
      create(:candidate_skill, candidate_id: candidate.id)
      pass_id = InterviewStatus.retrieve_by_name(InterviewStatus.pass).id
      Interview.update_status(interview.id, pass_id)
      candidate_changeset = Candidate.changeset(candidate, %{pipeline_status_id: PipelineStatus.retrieve_by_name(PipelineStatus.closed).id})
      Repo.update(candidate_changeset)
      response = get conn_with_dummy_authorization(), "/panelists/test/interviews?page"

      expect(response.status) |> to(be(200))
      [result_interview] = response.assigns.interviews.entries
      expect(compare_fields(result_interview, interview, [:id, :start_time])) |> to(be_true)
      expect(compare_fields(result_interview.candidate, Repo.get(Candidate, interview.candidate_id), [:name, :experience, :role_id, :other_skills])) |> to(be_true)
      expect(result_interview.last_interview_status) |> to(be(pass_id))
    end
  end

  describe "tech_one_interview_ids_between" do
    before do: Repo.delete_all(Interview)
    let :technical_one_id, do: InterviewType.retrieve_by_name(InterviewType.technical_1).id

    it "should give list of tech one interview ids between given two date ranges" do
      now = TimexHelper.utc_now()
      _non_tech_one = create(:interview, start_time: now |> TimexHelper.add(-2, :hours), end_time: now |> TimexHelper.add(-1, :hours))
      interview1 = create(:interview, interview_type_id: technical_one_id, start_time: now |> TimexHelper.add(-2, :hours), end_time: now |> TimexHelper.add(-1, :hours))
      interview2 = create(:interview, interview_type_id: technical_one_id, start_time: now |> TimexHelper.add(-1, :hours), end_time: now |> TimexHelper.add(-0, :hours))
      interview3 = create(:interview, interview_type_id: technical_one_id, start_time: now |> TimexHelper.add(-3, :hours), end_time: now |> TimexHelper.add(-2, :hours))
      _before_start_time = create(:interview, interview_type_id: technical_one_id, start_time: now |> TimexHelper.add(-4, :hours), end_time: now |> TimexHelper.add(-3, :hours))
      _after_end_time = create(:interview, interview_type_id: technical_one_id, start_time: now, end_time: now |> TimexHelper.add(1, :hours))

      interview_ids = Interview.tech_one_interview_ids_between(now |> TimexHelper.add(-3, :hours), now)
      expect(interview_ids) |> to(be([interview1.id, interview2.id, interview3.id]))
    end
  end
end
