defmodule RecruitxBackend.WeeklySignupReminderSpec do
  use ESpec.Phoenix, model: RecruitxBackend.WeeklySignupReminder

  import Ecto.Query

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Skill
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.WeeklySignupReminder

  let :role, do: insert(:role, name: "Role Name")
  let :candidate, do: insert(:candidate, role: role(), other_skills: "Other Skills", experience: Decimal.new(5.46))
  let :interview_type, do: insert(:interview_type)
  let :interview, do: insert(:interview, candidate: candidate(), interview_type: interview_type())

  describe "get candidates and interviews" do
    before do: Repo.delete_all(Interview)

    it "should return candidates of the given role with interviews based on sub query" do
      another_role = insert(:role, name: "Another Role Name")
      candidate_of_another_role = insert(:candidate, role: another_role, other_skills: "Other Skills", experience: Decimal.new(5.46))
      _interview_for_another_role = insert(:interview, candidate: candidate_of_another_role, interview_type: interview_type())

      expected_candidate_id = interview().candidate_id
      [ candidate | _ ] = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where(id: ^interview().id), role().id)

      expect(candidate.id) |> to(be(expected_candidate_id))
    end

    it "should return candidates of the given role with interviews based on sub query" do
      invalid_role_id = 0
      candidates = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where(id: ^interview().id), invalid_role_id)

      expect(candidates) |> to(be([]))
    end

    it "should return empty array when sub query returns empty result" do
      result = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where([i], i.id != ^interview().id), role().id)

      expect(result) |> to(be([]))
    end
  end

  describe "construct view data and returns it as a map" do
    before do
      insert(:candidate_skill, skill: insert(:skill, name: "Skill 1"), candidate: candidate())
      insert(:candidate_skill, skill: insert(:skill, name: "Skill 2"), candidate: candidate())
    end

    it "should conatin name, role and experience of candidate in the result" do
      candidates = WeeklySignupReminder.get_candidates_and_interviews(
        Interview
        |> where(id: ^interview().id)
        |> preload([:interview_type]),
        role().id
      )
      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates)

      expect(actual_data.name) |> to(be(candidate().first_name <> " " <> candidate().last_name))
      expect(actual_data.experience) |> to(be("5.5"))
      expect(actual_data.role) |> to(be(role().name))
    end

    it "should contain interview names and dates for the candidate in the result" do
      candidates_and_interviews = Interview
        |> where(id: ^interview().id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews(role().id)

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)
      [ actual_interview | _ ] = actual_data.interviews

      expect(actual_interview.name) |> to(be(interview_type().name))
      expect(actual_interview.date) |> to(be(TimexHelper.format_with_timezone(interview().start_time, "%b-%d")))
    end

    it "should contain concatenated skills for the candidate in the result" do
      candidates_and_interviews = Interview
        |> where(id: ^interview().id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews(role().id)

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)

      expect(actual_data.skills) |> to(have("Skill 1"))
      expect(actual_data.skills) |> to(have("Skill 2"))
    end

    it "should append other skills for the candidate in the result" do
      insert(:candidate_skill, skill: Skill.other_skill, candidate: candidate())
      candidates_and_interviews = Interview
        |> where(id: ^interview().id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews(role().id)

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)

      expect(actual_data.skills) |> to(have("Skill 1"))
      expect(actual_data.skills) |> to(have("Skill 2"))
      expect(actual_data.skills) |> to(have("Other Skills"))
    end
  end

  describe "get interview sub-query" do
    before do
      Repo.delete_all(Interview)
      insert(:interview, id: 1, start_time: get_start_of_current_week() |> TimexHelper.add(2, :days))
      insert(:interview, id: 2, start_time: get_start_of_current_week() |> TimexHelper.add(2, :days))
      insert(:interview, id: 3, start_time: get_start_of_current_week() |> TimexHelper.add(2, :days))
    end

    it "should return interviews with given interview ids and remaining ids in a different list" do
      {insufficient_panelists_query, sufficient_panelists_query} = WeeklySignupReminder.get_interview_sub_queries([1])
      [interview1] = insufficient_panelists_query |> Repo.all
      [interview2, interview3] = sufficient_panelists_query |> Repo.all

      expect(interview1.id) |> to(be(1))
      expect(interview2.id) |> to(be(2))
      expect(interview3.id) |> to(be(3))
    end

    it "should return interviews with given interview ids and remaining ids in a different list when the given list is empty" do
      {insufficient_panelists_query, sufficient_panelists_query} = WeeklySignupReminder.get_interview_sub_queries([])
      interviews_with_insufficient_panelists = insufficient_panelists_query |> Repo.all
      [interview1, interview2, interview3] = sufficient_panelists_query |> Repo.all

      expect(interviews_with_insufficient_panelists) |> to(be([]))
      expect(interview1.id) |> to(be(1))
      expect(interview2.id) |> to(be(2))
      expect(interview3.id) |> to(be(3))
    end

    it "should not return interviews that is not in next 7 days" do
      insert(:interview, id: 4, start_time: TimexHelper.utc_now() |> TimexHelper.add(-10, :days))
      {insufficient_panelists_query, sufficient_panelists_query} = WeeklySignupReminder.get_interview_sub_queries([])
      interviews_with_insufficient_panelists = insufficient_panelists_query |> Repo.all
      [interview1, interview2, interview3] = sufficient_panelists_query |> Repo.all

      expect(interviews_with_insufficient_panelists) |> to(be([]))
      expect(interview1.id) |> to_not(be(4))
      expect(interview2.id) |> to_not(be(4))
      expect(interview3.id) |> to_not(be(4))
    end

    it "should not return signed up interviews that is not in next 7 days" do
      insert(:interview, id: 4, start_time: get_start_of_next_week() |> TimexHelper.add(10, :days))
      {insufficient_panelists_query, sufficient_panelists_query} = WeeklySignupReminder.get_interview_sub_queries([1])
      [interview1] = insufficient_panelists_query |> Repo.all
      [interview2, interview3] = sufficient_panelists_query |> Repo.all

      expect(interview1.id) |> to_not(be(4))
      expect(interview2.id) |> to_not(be(4))
      expect(interview3.id) |> to_not(be(4))
    end
  end

  describe "execute weekly signup reminder" do
    it "should call Swoosh deliver with correct arguments" do
      insert(:interview, start_time: get_start_of_current_week() |> TimexHelper.add(2, :days))
      RecruitxBackend.MailHelper.default_mail

      allow Swoosh.Templates |> to(accept(:weekly_signup_reminder, fn(_, _) -> "html content"  end))
      allow RecruitxBackend.MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      WeeklySignupReminder.execute

      expect Swoosh.Templates |> to(accepted :weekly_signup_reminder)
      expect RecruitxBackend.MailHelper |> to(accepted :deliver )
    end

    it "should not call MailmanExtensions deliver if there are no interviews" do
      Repo.delete_all(Interview)

      RecruitxBackend.MailHelper.default_mail

      allow Swoosh.Templates |> to(accept(:weekly_signup_reminder, fn(_, _) -> "html content"  end))
      allow RecruitxBackend.MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      WeeklySignupReminder.execute

      expect Swoosh.Templates |> (to_not(accepted :weekly_signup_reminder))
      expect RecruitxBackend.MailHelper |> (to_not(accepted :deliver))
    end

    it "should be called every week on tuesday at 8:00 AM" do
      job = Quantum.find_job(:weekly_signup_reminder)

      expect(job.schedule) |> to(be("30 02 * * 2"))
      expect(job.task) |> to(be({"RecruitxBackend.WeeklySignupReminder", "execute"}))
    end
  end
end
