defmodule RecruitxBackend.EmailIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.WeeklySignupReminder

  alias RecruitxBackend.WeeklySignupReminder
  alias Mailman.TestServer
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Skill
  alias Timex.DateFormat

  @moduletag :integration

  describe "weekly signup reminder" do
    let :date_time, do: Timex.Date.now |> Timex.Date.shift(hours: 2)
    let :skill, do: create(:skill, name: "Special Skill")
    let :interview_type, do: create(:interview_type, name: "Round 1")
    let :candidate, do: create(:candidate, other_skills: "Other Skill")

    before do
      Repo.delete_all(Interview)
      create(:candidate_skill, skill_id: skill.id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: Skill.other_skill_id, candidate_id: candidate.id)
      create(:interview, interview_type_id: interview_type.id, start_time: date_time, candidate_id: candidate.id)
    end

    it "should send interview signup details as email" do
      Task.await(WeeklySignupReminder.execute)
      [delivery] = TestServer.deliveries

      expect(delivery) |> to_not(be([]))
      expect(delivery) |> to(have("From: no-reply-recruitx@thoughtworks.com"))
      expect(delivery) |> to(have("To: Chennai <chennai@thoughtworks.com>"))
      expect(delivery) |> to(have("Subject: [RecruitX] Signup Reminder"))
      expect(delivery) |> to(have(candidate.first_name <> " " <> candidate.last_name))
      expect(delivery) |> to(have(to_string(Decimal.round(candidate.experience, 1))))
      expect(delivery) |> to(have("Special Skill, Other Skill"))
      expect(delivery) |> to(have("Round 1 on " <> DateFormat.format!(date_time, "%b-%d", :strftime) ))
    end
  end
end
