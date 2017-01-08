defmodule RecruitxBackend.SlotCancellationNotificationSpec do
  use ESpec.Phoenix, model: RecruitxBackend.SlotCancellationNotification

  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotCancellationNotification
  alias RecruitxBackend.TimexHelper

  describe "execute" do
    it "should not send mail when there are no slots to be cancelled" do
      Repo.delete_all Slot
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      Slot |> SlotCancellationNotification.execute

      expect MailHelper |> (to_not(accepted :deliver))
    end

    it "should not send mail when the cancelled slots do not have sign ups" do
      Repo.delete_all Slot
      create(:slot)
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      Slot |> SlotCancellationNotification.execute

      expect MailHelper |> (to_not(accepted :deliver))
    end

    it "should send mail to the panelist of the deleted slots" do
      Repo.delete_all Slot
      interview_type = create(:interview_type, name: "roundone")
      slot = create(:slot,
        interview_type_id: interview_type.id,
        start_time: TimexHelper.from_epoch([datetime: {{2011,1,1}, {12,30,0}}]))
      create(:slot_panelist, panelist_login_name: "test", slot_id: slot.id)

      allow MailHelper |> to(accept(:deliver, fn(%{subject: subject, to: to_addresses, html_body: {
        interview_name, interview_time }}) ->
          expect subject |> to(eql("[RecruitX] roundone on 01/01/11 18:00 is cancelled"))
          expect to_addresses |> to(eql(["test@x.com"]))
          expect interview_name |> to(eql("roundone"))
          expect interview_time |> to(eql("01/01/11 18:00"))
      end))

      allow Swoosh.Templates |> to(accept(:slot_cancellation_notification, &({&1, &2})))
      allow System |> to(accept(:get_env, fn(_) -> "@x.com" end))

      (from i in Slot, where: i.id == ^slot.id) |> SlotCancellationNotification.execute

       expect MailHelper |> to(accept(:deliver))
    end
  end
end
