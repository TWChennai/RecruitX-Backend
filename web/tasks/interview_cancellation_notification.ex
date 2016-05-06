defmodule RecruitxBackend.InterviewCancellationNotification do
  import Ecto.Query, only: [preload: 2, from: 2, select: 3]

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo
  alias RecruitxBackend.MailHelper
  alias Timex.DateFormat
  alias Timex.Date
  alias Timex.Timezone
  alias Swoosh.Templates

  def execute(interviews_to_delete_query) do
    (from q in interviews_to_delete_query,
    join: ip in assoc(q, :interview_panelist),
    preload: ([:candidate, :interview_type]),
    select: {q, ip})
    |> Repo.all
    |> deliver_mail_for_cancelled_interview_rounds
  end

  def deliver_mail_for_cancelled_interview_rounds([]), do: :ok

  def deliver_mail_for_cancelled_interview_rounds([{interview_round, interview_panelist} | rest]) do
    MailHelper.deliver %{
      subject: "[RecruitX] Interview Cancellation",
      to: [interview_panelist.panelist_login_name |> InterviewPanelist.get_email_address],
      html_body: Templates.interview_cancellation_notification(interview_round.candidate.first_name,
        interview_round.candidate.last_name,
        interview_round.interview_type.name,
        interview_round.start_time
        |> Date.from
        |> Timezone.convert("Asia/Kolkata")
        |> DateFormat.format!("%d/%m/%y %H:%M", :strftime))
    }
    deliver_mail_for_cancelled_interview_rounds(rest)
  end
end
