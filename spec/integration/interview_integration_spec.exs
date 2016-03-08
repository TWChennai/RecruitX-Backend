defmodule RecruitxBackend.InterviewIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.Repo

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  describe "index" do
    before do: Repo.delete_all(Candidate)

    it "should return empty when panelist has taken no interviews" do
      create(:interview)

      response = get conn_with_dummy_authorization(), "/panelists/recruitx/interviews?page"

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

    it "should return list of interviews that the panelist has taken with the last interview statuts if pipeline is closed and all rounds are over" do
      Repo.delete_all Candidate
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
end
