defmodule RecruitxBackend.InterviewIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  describe "index" do
    before do: Repo.delete_all(Interview)
    before do: Repo.delete_all(InterviewPanelist)
    before do: Repo.delete_all(CandidateSkill)
    before do: Repo.delete_all(Candidate)

    it "should return empty when panelist has taken no interviews" do
      create(:interview)

      response = get conn(), "/panelists/recruitx/interviews"

      expect(response.status) |> to(be(200))
      expect(response.assigns.interviews) |> to(be([]))
    end

    it "should return list of interviews that the panelist has taken" do
      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id, candidate: candidate)
      create(:candidate_skill, candidate_id: candidate.id, candidate: candidate)
      create(:interview_panelist, panelist_login_name: "test", interview_id: interview.id)

      response = get conn(), "/panelists/test/interviews"

      expect(response.status) |> to(be(200))
      [result_interview] = response.assigns.interviews
      expect(compare_fields(result_interview, interview, [:id, :start_time])) |> to(be_true)
      expect(compare_fields(result_interview.candidate, interview.candidate, [:name, :experience, :role_id, :other_skills])) |> to(be_true)
    end
  end
end
