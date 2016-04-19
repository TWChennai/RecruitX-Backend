defmodule RecruitxBackend.EmailIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.WeeklySignupReminder

  alias RecruitxBackend.WeeklySignupReminder
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Skill
  alias Timex.DateFormat

  @moduletag :integration

  describe "weekly signup reminder" do
    let :skill, do: create(:skill, name: "Special Skill")
    let :interview_type, do: create(:interview_type, name: "Round 1")
    let :candidate, do: create(:candidate, other_skills: "Other Skill")

    before do
      Repo.delete_all(Interview)
      create(:candidate_skill, skill_id: skill.id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: Skill.other_skill_id, candidate_id: candidate.id)
      create(:interview, interview_type_id: interview_type.id, start_time: get_start_of_next_week, candidate_id: candidate.id)
    end

    it "should send interview signup details as email" do
      email = WeeklySignupReminder.execute

      mail_box = Swoosh.InMemoryMailbox.all |> List.first

      expect(mail_box) |> to(be(email))
      expect(mail_box) |> to_not(be([]))
      expect(mail_box.to) |> to(be([{"",System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES")}]))
      expect(mail_box.subject) |> to(have("[RecruitX] Signup Reminder"))
      expect(mail_box.html_body) |> to(have(candidate.first_name <> " " <> candidate.last_name))
      mail_content = mail_box.html_body
      expect(mail_content) |> to(have(to_string(Decimal.round(candidate.experience, 1))))
      expect(mail_content) |> to(have("Special Skill, Other Skill"))
      expect(mail_content) |> to(have("Round 1 on " <> DateFormat.format!(get_start_of_next_week, "%b-%d", :strftime) ))
    end
  end
end
