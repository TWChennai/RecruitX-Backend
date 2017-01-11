defmodule RecruitxBackend.InterviewCancellationNotificationSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewCancellationNotification

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewCancellationNotification
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Repo
  alias RecruitxBackend.TimexHelper

  describe "execute" do
    before do: Repo.delete_all(Interview)

    it "should not send mail when there are no interviews to be cancelled" do
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      Interview |> InterviewCancellationNotification.execute

      expect MailHelper |> (to_not(accepted :deliver))
    end

    it "should not send mail when the cancelled interviews do not have sign ups" do
      create(:interview)
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      Interview |> InterviewCancellationNotification.execute

      expect MailHelper |> (to_not(accepted :deliver))
    end

    it "should send mail to the panelist of the cancelled interview" do
      candidate = create(:candidate, first_name: "testing", last_name: "last")
      interview_type = create(:interview_type, name: "roundone")
      interview = create(:interview,
        candidate_id: candidate.id,
        interview_type_id: interview_type.id,
        start_time: TimexHelper.from_epoch([datetime: {{2011,1,1}, {12,30,0}}]))
      create(:interview_panelist, panelist_login_name: "test", interview_id: interview.id)

      allow MailHelper |> to(accept(:deliver, fn(%{subject: subject, to: to_addresses, html_body: {
        candidate_first_name, candidate_last_name, interview_name, interview_time }}) ->
          expect subject |> to(eql("[RecruitX] roundone on 01/01/11 18:00 is cancelled"))
          expect to_addresses |> to(eql(["test@x.com"]))
          expect candidate_first_name |> to(eql("testing"))
          expect candidate_last_name |> to(eql("last"))
          expect interview_name |> to(eql("roundone"))
          expect interview_time |> to(eql("01/01/11 18:00"))
      end))

      allow Swoosh.Templates |> to(accept(:interview_cancellation_notification, &({&1, &2, &3, &4})))
      allow System |> to(accept(:get_env, fn(_) -> "@x.com" end))

      (from i in Interview, where: i.id == ^interview.id) |> InterviewCancellationNotification.execute

      expect MailHelper |> to(accept(:deliver))
    end
  end
end
