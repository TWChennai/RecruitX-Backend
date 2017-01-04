defmodule RecruitxBackend.EmailIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.WeeklySignupReminder

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Skill
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.WeeklySignupReminder

  @moduletag :integration

  describe "weekly signup reminder" do
    let :skill, do: insert(:skill, name: "Special Skill")
    let :interview_type, do: insert(:interview_type, name: "Round 1")
    let :role, do: insert(:role, name: "Role1")
    let :candidate, do: insert(:candidate, other_skills: "Other Skill",
    role: role())

    before do
      Repo.delete_all(Interview)
      Swoosh.Adapters.Local.Storage.Memory.delete_all()
      insert(:candidate_skill, skill: skill(), candidate: candidate())
      insert(:candidate_skill, skill: Skill.other_skill, candidate: candidate())
      insert(:interview, interview_type: interview_type(), start_time:
      get_start_of_current_week() |> TimexHelper.add(2, :days), candidate: candidate())
    end

    it "should send multiple interview signup as email for each role" do
      another_role = insert(:role, name: "Role2")
      candidate_of_another_role = insert(:candidate, other_skills: "Other Skill",
          role: another_role)
      insert(:interview, interview_type: interview_type(),
        start_time: get_start_of_current_week() |> TimexHelper.add(2, :days),
        candidate: candidate_of_another_role)

        WeeklySignupReminder.execute
        mail_box = Swoosh.Adapters.Local.Storage.Memory.all

        expect(mail_box |> Enum.count) |> to(be(2))
        [first_email, second_email] = mail_box
        subjects = [first_email.subject, second_email.subject]
        expect(subjects) |> to(have("[RecruitX] " <> role().name <> " Signup Reminder"))
        expect(subjects) |> to(have("[RecruitX] " <> another_role.name <> " Signup Reminder"))
    end

    it "should send interview signup details as email" do
      WeeklySignupReminder.execute
      mail_box = Swoosh.Adapters.Local.Storage.Memory.all

      expect(mail_box |> Enum.count) |> to(be(1))
      [first_email] = mail_box
      expect(first_email.to) |> to(be([{"", System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES")}]))
      expect(first_email.subject) |> to(have("[RecruitX] " <> role().name <> " Signup Reminder"))
      expect(first_email.html_body) |> to(have(candidate().first_name <> " " <> candidate().last_name))
      mail_content = first_email.html_body
      expect(mail_content) |> to(have(to_string(Decimal.round(candidate().experience, 1))))
      expect(mail_content) |> to(have("Special Skill, Other Skill"))
      expect(mail_content) |> to(have("Round 1 on " <> TimexHelper.format_with_timezone(get_start_of_current_week() |> TimexHelper.add(2, :days), "%b-%d")))
    end
  end
end
