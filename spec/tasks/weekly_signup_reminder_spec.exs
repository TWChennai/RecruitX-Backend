defmodule RecruitxBackend.WeeklySignupReminderSpec do
  use ESpec.Phoenix, model: RecruitxBackend.WeeklySignupReminder

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Skill
  alias RecruitxBackend.WeeklySignupReminder
  alias Timex.Date

  describe "get candidates and interviews" do
    before do
      Repo.delete_all(Interview)
    end

    let :interview, do: create(:interview)

    it "should return candidates with interviews based on sub query" do
      expected_candidate_id = interview.candidate_id
      [ candidate | _ ] = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where(id: ^interview.id))

      expect(candidate.id) |> to(be(expected_candidate_id))
    end

    it "should return empty array when sub query returns empty result" do
      result = WeeklySignupReminder.get_candidates_and_interviews(Interview |> where([i], i.id != ^interview.id))

      expect(result) |> to(be([]))
    end
  end

  describe "construct view data and returns it as a map" do
    let :role, do: create(:role, name: "Role Name")
    let :candidate, do: create(:candidate, role_id: role.id, other_skills: "Other Skills", experience: Decimal.new(5.46))
    let :interview_type, do: create(:interview_type)
    let :interview, do: create(:interview, candidate_id: candidate.id, interview_type_id: interview_type.id)

    before do
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)
    end

    it "should conatin name, role and experience of candidate in the result" do
      candidates = WeeklySignupReminder.get_candidates_and_interviews(
        Interview
        |> where(id: ^interview.id)
        |> preload([:interview_type])
      )
      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates)

      expect(actual_data.name) |> to(be(candidate.first_name <> " " <> candidate.last_name))
      expect(actual_data.experience) |> to(be("5.5"))
      expect(actual_data.role) |> to(be(role.name))
    end

    it "should contain interview names and dates for the candidate in the result" do
      candidates_and_interviews = Interview
        |> where(id: ^interview.id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)
      [ actual_interview | _ ] = actual_data.interviews

      expect(actual_interview.name) |> to(be(interview_type.name))
      expect(actual_interview.date) |> to(be(Timex.DateFormat.format!(interview.start_time, "%b-%d", :strftime)))
    end

    it "should contain concatenated skills for the candidate in the result" do
      candidates_and_interviews = Interview
        |> where(id: ^interview.id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)

      expect(actual_data.skills) |> to(have("Skill 1"))
      expect(actual_data.skills) |> to(have("Skill 2"))
    end

    it "should append other skills for the candidate in the result" do
      create(:candidate_skill, skill_id: Skill.other_skill_id, candidate_id: candidate.id)
      candidates_and_interviews = Interview
        |> where(id: ^interview.id)
        |> preload([:interview_type])
        |> WeeklySignupReminder.get_candidates_and_interviews

      [ actual_data | _ ] = WeeklySignupReminder.construct_view_data(candidates_and_interviews)

      expect(actual_data.skills) |> to(have("Skill 1"))
      expect(actual_data.skills) |> to(have("Skill 2"))
      expect(actual_data.skills) |> to(have("Other Skills"))
    end
  end

  describe "get interview sub-query" do
    before do
      Repo.delete_all(Interview)
      create(:interview, id: 1)
      create(:interview, id: 2)
      create(:interview, id: 3)
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
      create(:interview, id: 4, start_time: Date.now |> Date.shift(days: -10))
      {insufficient_panelists_query, sufficient_panelists_query} = WeeklySignupReminder.get_interview_sub_queries([])
      interviews_with_insufficient_panelists = insufficient_panelists_query |> Repo.all
      [interview1, interview2, interview3] = sufficient_panelists_query |> Repo.all

      expect(interviews_with_insufficient_panelists) |> to(be([]))
      expect(interview1.id) |> to_not(be(4))
      expect(interview2.id) |> to_not(be(4))
      expect(interview3.id) |> to_not(be(4))
    end

    it "should not return signed up interviews that is not in next 7 days" do
      create(:interview, id: 4, start_time: Date.now |> Date.shift(days: 10))
      {insufficient_panelists_query, sufficient_panelists_query} = WeeklySignupReminder.get_interview_sub_queries([1])
      [interview1] = insufficient_panelists_query |> Repo.all
      [interview2, interview3] = sufficient_panelists_query |> Repo.all

      expect(interview1.id) |> to_not(be(4))
      expect(interview2.id) |> to_not(be(4))
      expect(interview3.id) |> to_not(be(4))
    end
  end

  describe "execute weekly signup reminder" do
    it "should call MailmanExtensions deliver with correct arguments" do
      create(:interview)
      email = %{
        subject: "[RecruitX] Signup Reminder",
        to: System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
        html: "html content"
      }
      allow MailmanExtensions.Templates |> to(accept(:weekly_signup_reminder, fn(_, _) -> "html content"  end))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, fn(_) -> "" end))

      WeeklySignupReminder.execute

      expect MailmanExtensions.Templates |> to(accepted :weekly_signup_reminder)
      expect MailmanExtensions.Mailer |> to(accepted :deliver, [email])
    end

    it "should not call MailmanExtensions deliver if there are no interviews" do
      Repo.delete_all(Interview)
      email = %{
        subject: "[RecruitX] Signup Reminder",
        to: System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
        html: "html content"
      }
      allow MailmanExtensions.Templates |> to(accept(:weekly_signup_reminder, fn(_, _) -> "html content"  end))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, fn(_) -> "" end))

      WeeklySignupReminder.execute

      expect MailmanExtensions.Templates |> (to_not(accepted :weekly_signup_reminder))
      expect MailmanExtensions.Mailer |> (to_not(accepted :deliver, [email]))
    end

    it "should be called every week on friday at 3.0 UTC" do
      job = Quantum.find_job(:weekly_signup_reminder)

      expect(job.schedule) |> to(be("30 11 * * 5"))
      expect(job.task) |> to(be({"RecruitxBackend.WeeklySignupReminder", "execute"}))
    end
  end
end
