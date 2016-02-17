defmodule RecruitxBackend.InterviewIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Repo

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  describe "index" do
    before do: Repo.delete_all(Candidate)

    it "should return empty when panelist has taken no interviews" do
      create(:interview)

      response = get conn(), "/panelists/recruitx/interviews"

      expect(response.status) |> to(be(200))
      expect(response.assigns.interviews) |> to(be([]))
    end

    it "should return list of interviews that the panelist has taken" do
      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id)
      create(:candidate_skill, candidate_id: candidate.id)
      create(:interview_panelist, panelist_login_name: "test", interview_id: interview.id)

      response = get conn(), "/panelists/test/interviews"

      expect(response.status) |> to(be(200))
      [result_interview] = response.assigns.interviews
      expect(compare_fields(result_interview, interview, [:id, :start_time])) |> to(be_true)
      expect(compare_fields(result_interview.candidate, Repo.get(Candidate, interview.candidate_id), [:name, :experience, :role_id, :other_skills])) |> to(be_true)
    end
  end
end
