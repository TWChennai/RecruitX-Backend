defmodule RecruitxBackend.SosEmailSpec do
  use ESpec.Phoenix, model: RecruitxBackend.SosEmail

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SosEmail
  alias RecruitxBackend.TimexHelper

  describe "execute" do
    before do: Repo.delete_all(Interview)

    it "should not send an email when there all interviews have sufficient signups" do
      interview = insert(:interview)
      Repo.insert(%InterviewPanelist{panelist_login_name: "test1", interview_id: interview.id})
      Repo.insert(%InterviewPanelist{panelist_login_name: "test2", interview_id: interview.id})
      allow Swoosh.Templates |> to(accept(:sos_email, fn(_) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      result = SosEmail.execute

      expect result |> (to(be(nil)))
      expect MailHelper |> (to_not(accepted :deliver))
      expect Swoosh.Templates |> (to_not(accepted :sos_email))
    end

    it "should send an email with the formatted data ordered by start time within the next 48 hours only" do
      allow Timex |> to(accept(:now, fn()-> TimexHelper.from_epoch([date: {2010, 12, 31}]) end))
      insert(:interview, start_time: TimexHelper.from_epoch([datetime: {{2011,1,1}, {12,30,0}}]))
      insert(:interview, start_time: TimexHelper.from_epoch([date: {2011, 3, 1}]))
      allow Swoosh.Templates |> to(accept(:sos_email, &(&1)))
      allow MailHelper |> to(accept(:deliver, &(&1)))

      %{html_body: [interview1]} = SosEmail.execute

      expect interview1.date |> to(eql("01/01/11 18:00"))
    end

    it "should send an email with the formatted data when there are interviews with less than required signups" do
      Repo.delete_all InterviewPanelist
      interview = insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :days))
      Repo.insert(%InterviewPanelist{panelist_login_name: "test", interview_id: interview.id})
      allow Swoosh.Templates |> to(accept(:sos_email, &(&1)))
      allow MailHelper |> to(accept(:deliver, &(&1)))

      %{html_body: [%{count_of_panelists_required: count_of_panelists_required}]} = SosEmail.execute

      expect(count_of_panelists_required) |> to(be(1))
    end

    it "should send an email with the formatted data when there are interviews with zero signups" do
      allow Timex |> to(accept(:now, fn()-> TimexHelper.from_epoch([date: {2010, 12, 31}]) end))
      role = insert(:role)
      candidate = insert(:candidate, role: role, experience: Decimal.new(1))
      insert(:candidate_skill, skill: insert(:skill, name: "test skill1"), candidate: candidate)
      insert(:candidate_skill, skill: insert(:skill, name: "test skill2"), candidate: candidate)
      interview_type = insert(:interview_type)
      insert(:interview, candidate: candidate, interview_type: interview_type, start_time: TimexHelper.from_epoch([datetime: {{2011,1,1}, {12,30,0}}]))
      allow Swoosh.Templates |> to(accept(:sos_email, &(&1)))
      allow MailHelper |> to(accept(:deliver, &(&1)))
      allow System |> to(accept(:get_env, &(&1)))

      %{subject: subject, to: to_addresses, html_body: [interview]} = SosEmail.execute

      expect MailHelper |> to(accept(:deliver))
      expect subject |> to(eql("[RecruitX] Signup Reminder - Urgent"))
      expect to_addresses |> to(eql(["WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES"]))
      expect interview.candidate.name |> to(eql(candidate.first_name <> " " <> candidate.last_name))
      expect interview.candidate.role |> to(eql(role.name))
      expect interview.candidate.experience |> to(eql("1.0"))
      expect interview.name |> to(eql(interview_type.name))
      expect interview.date |> to(eql("01/01/11 18:00"))
      expect interview.candidate.skills |> to(have("test skill1"))
      expect interview.candidate.skills |> to(have("test skill2"))
      expect interview.count_of_panelists_required |> to(eql(interview_type.max_sign_up_limit))
    end
  end
end
