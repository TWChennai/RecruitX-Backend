defmodule RecruitxBackend.EmailIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.WeeklySignupReminder

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Skill
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.WeeklySignupReminder

  @moduletag :integration

  describe "weekly signup reminder" do
    let :skill, do: create(:skill, name: "Special Skill")
    let :interview_type, do: create(:interview_type, name: "Round 1")
    let :role, do: create(:role, name: "Role1")
    let :candidate, do: create(:candidate, other_skills: "Other Skill",
    role_id: role.id)

    before do
      Repo.delete_all(Interview)
      Swoosh.InMemoryMailbox.delete_all()
      create(:candidate_skill, skill_id: skill.id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: Skill.other_skill.id, candidate_id: candidate.id)
      create(:interview, interview_type_id: interview_type.id, start_time:
      get_start_of_current_week |> TimexHelper.add(2, :days), candidate_id: candidate.id)
    end

    it "should send multiple interview signup as email for each role" do
      another_role = create(:role, name: "Role2")
      candidate_of_another_role = create(:candidate, other_skills: "Other Skill",
          role_id: another_role.id)
      create(:interview, interview_type_id: interview_type.id,
        start_time: get_start_of_current_week |> TimexHelper.add(2, :days),
        candidate_id: candidate_of_another_role.id)

        WeeklySignupReminder.execute
        mail_box = Swoosh.InMemoryMailbox.all

        expect(mail_box |> Enum.count) |> to(be(2))
        [first_email, second_email] = mail_box
        subjects = [first_email.subject, second_email.subject]
        expect(subjects) |> to(have(
        "[RecruitX] " <> role.name <> " Signup Reminder"))
        expect(subjects) |> to(have(
        "[RecruitX] " <> another_role.name <> " Signup Reminder"))
    end

    it "should send interview signup details as email" do
      WeeklySignupReminder.execute
      mail_box = Swoosh.InMemoryMailbox.all

      expect(mail_box |> Enum.count) |> to(be(1))
      [first_email] = mail_box
      expect(first_email.to) |> to(be(
      [{"",System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES")}]))
      expect(first_email.subject) |> to(have(
      "[RecruitX] " <> role.name <> " Signup Reminder"))
      expect(first_email.html_body) |> to(have(
      candidate.first_name <> " " <> candidate.last_name))
      mail_content = first_email.html_body
      expect(mail_content) |> to(have(to_string(Decimal.round(candidate.experience, 1))))
      expect(mail_content) |> to(have("Special Skill, Other Skill"))
      expect(mail_content) |> to(have("Round 1 on " <> TimexHelper.format_with_timezone(get_start_of_current_week |> TimexHelper.add(2, :days), "%b-%d")))
    end
  end
end
