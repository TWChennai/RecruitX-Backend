defmodule RecruitxBackend.SosEmailSpec do
  use ESpec.Phoenix, model: RecruitxBackend.SosEmail

  alias RecruitxBackend.SosEmail
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo
  alias Timex.Date

  describe "execute" do
    it "should not send an email when there all interviews have sufficient signups" do
      Repo.delete_all Interview

      interview = create(:interview)
      Repo.insert(%InterviewPanelist{panelist_login_name: "test1", interview_id: interview.id})
      Repo.insert(%InterviewPanelist{panelist_login_name: "test2", interview_id: interview.id})
      allow MailmanExtensions.Templates |> to(accept(:sos_email, fn(_) -> "html content"  end))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, fn(_) -> "" end))

      SosEmail.execute

      expect MailmanExtensions.Mailer |> (to_not(accepted :deliver))
      expect MailmanExtensions.Templates |> (to_not(accepted :sos_email))
    end

    it "should send an email with the formatted data ordered by start time within the next 48 hours only" do
      Repo.delete_all Interview

      allow Timex.Date |> to(accept(:now, fn()-> Date.set(Date.epoch, [date: {2010, 12, 31}]) end))
      create(:interview, start_time: Date.set(Date.epoch, [date: {2011, 1, 1}]))
      create(:interview, start_time: Date.set(Date.epoch, [date: {2011, 3, 1}]))
      allow MailmanExtensions.Templates |> to(accept(:sos_email, &(&1)))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, &(&1)))

      %{html: [interview1]} = SosEmail.execute

      expect interview1.date |> to(eql("Jan-01"))
    end

    it "should send an email with the formatted data when there are interviews with less than required signups" do
      Repo.delete_all Interview
      Repo.delete_all InterviewPanelist
      allow Timex.Date |> to(accept(:now, fn()-> Date.set(Date.epoch, [date: {2010, 12, 31}]) end))
      interview = create(:interview, start_time: Date.set(Date.epoch, [date: {2011, 1, 1}]))
      Repo.insert(%InterviewPanelist{panelist_login_name: "test", interview_id: interview.id})
      allow MailmanExtensions.Templates |> to(accept(:sos_email, &(&1)))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, &(&1)))

      %{html: [%{count_of_panelists_required: count_of_panelists_required}]} = SosEmail.execute

      expect(count_of_panelists_required) |> to(be(1))
    end

    it "should send an email with the formatted data when there are interviews with zero signups" do
      Repo.delete_all Interview
      allow Timex.Date |> to(accept(:now, fn()-> Date.set(Date.epoch, [date: {2010, 12, 31}]) end))
      role = create(:role)
      candidate = create(:candidate, role_id: role.id, experience: Decimal.new(1))
      create(:candidate_skill, skill_id: create(:skill, name: "test skill1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "test skill2").id, candidate_id: candidate.id)
      interview_type = create(:interview_type)
      create(:interview, candidate_id: candidate.id, interview_type_id: interview_type.id, start_time: Date.set(Date.epoch, [date: {2011, 1, 1}]))
      allow MailmanExtensions.Templates |> to(accept(:sos_email, &(&1)))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, &(&1)))
      allow System |> to(accept(:get_env, &(&1)))

      %{subject: subject, to: to_addresses, html: [interview]} = SosEmail.execute

     expect MailmanExtensions.Mailer |> to(accept(:deliver))
     expect subject |> to(eql("[RecruitX] SOS Signup Reminder"))
     expect to_addresses |> to(eql(["WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES"]))
     expect interview.candidate.name |> to(eql(candidate.first_name <> " " <> candidate.last_name))
     expect interview.candidate.role |> to(eql(role.name))
     expect interview.candidate.experience |> to(eql("1.0"))
     expect interview.name |> to(eql(interview_type.name))
     expect interview.date |> to(eql("Jan-01"))
     expect interview.candidate.skills |> to(eql("test skill1, test skill2"))
     expect interview.count_of_panelists_required |> to(eql(interview_type.max_sign_up_limit))
    end
  end
end
