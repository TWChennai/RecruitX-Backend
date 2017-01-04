defmodule RecruitxBackend.SlotCancellationNotification do
  import Ecto.Query, only: [from: 2]

  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Panel
  alias RecruitxBackend.Repo
  alias RecruitxBackend.TimexHelper
  alias Swoosh.Templates

  def execute(slots_to_delete_query) do
    (from q in slots_to_delete_query,
    join: sp in assoc(q, :slot_panelists),
    preload: ([:role, :interview_type]),
    select: {q, sp})
    |> Repo.all
    |> deliver_mail_for_cancelled_slots
  end

  def deliver_mail_for_cancelled_slots([]), do: :ok

  def deliver_mail_for_cancelled_slots([{slot, slot_panelist} | rest]) do
    formatted_date = TimexHelper.format_with_timezone(slot.start_time, "%d/%m/%y %H:%M")

    MailHelper.deliver %{
      subject: "[RecruitX] " <> slot.interview_type.name <> " on " <> formatted_date <> " is cancelled",
      to: [slot_panelist.panelist_login_name |> Panel.get_email_address],
      html_body: Templates.slot_cancellation_notification(slot.interview_type.name,
        formatted_date)
    }
    deliver_mail_for_cancelled_slots(rest)
  end
end
