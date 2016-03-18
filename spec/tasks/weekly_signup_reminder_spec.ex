defmodule RecruitxBackend.WeeklySignupReminderSpec do
	use ESpec.Phoenix, model: RecruitxBackend.WeeklySignupReminder

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Skill
  alias RecruitxBackend.WeeklySignupReminder

  describe "get candidates and interviews" do
    let :interview, do: create(:interview)

    it "should return candidates with interviews based on sub query" do
      [ candidate | _ ] = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where([i], i.id == ^interview.id))

      expect(candidate.id) |> to(be(interview.candidate_id))
    end

    it "should return empty array when sub query returns empty result" do
      result = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where([i], i.id != ^interview.id))

      expect(result) |> to(be([]))
    end
	end

  describe "construct view data and returns it as a map" do
    let :role, do: create(:role, name: "Role Name")
    let :candidate, do: create(:candidate, role_id: role.id, other_skills: "Other Skills")
    let :interview_type, do: create(:interview_type)
    let :interview, do: create(:interview, candidate_id: candidate.id, interview_type_id: interview_type.id)
    before do
			create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
			create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)
		end

    it "should conatin name, role and experience of candidate in the result" do
      candidates = WeeklySignupReminder.get_candidates_and_interviews(
        Interview
        |> where([i], i.id == ^interview.id)
        |> preload([:interview_type])
      )
      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates)

      expect(actual_data.name) |> to(be(candidate.first_name <> " " <> candidate.last_name))
      expect(actual_data.experience) |> to(be(candidate.experience))
      expect(actual_data.role) |> to(be(role.name))
    end

    it "should contain interview names and dates for the candidate in the result" do
      candidates_and_interviews = Interview
        |> where([i], i.id == ^interview.id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)
      [ actual_interview | _ ] = actual_data.interviews

      expect(actual_interview.name) |> to(be(interview_type.name))
      expect(actual_interview.date) |> to(be(Timex.DateFormat.format!(interview.start_time, "%b-%d", :strftime)))
    end

    it "should contain concatenated skills for the candidate in the result" do
      candidates_and_interviews = Interview
        |> where([i], i.id == ^interview.id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)

      expect(actual_data.skills) |> to(be("Skill 1, Skill 2"))
    end

    it "should append other skills for the candidate in the result" do
			create(:candidate_skill, skill_id: Skill.other_skill_id, candidate_id: candidate.id)
      candidates_and_interviews = Interview
        |> where([i], i.id == ^interview.id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)

      expect(actual_data.skills) |> to(be("Skill 1, Skill 2, Other Skills"))
    end
  end
end
