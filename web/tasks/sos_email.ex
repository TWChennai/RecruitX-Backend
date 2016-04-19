defmodule RecruitxBackend.SosEmail do
  import Ecto.Query, only: [preload: 2, order_by: 2, where: 2, select: 3]

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.MailHelper
  alias Swoosh.Templates
  alias Timex.Date

  def execute do
    interviews_with_insufficient_panelists = get_interviews_with_insufficient_panelists |> construct_view_data

    if interviews_with_insufficient_panelists != [] do
      MailHelper.deliver %{
        subject: "[RecruitX] Signup Reminder - Urgent",
        to: System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
        html_body: interviews_with_insufficient_panelists |> Templates.sos_email
      }
    end
  end

  def get_interviews_with_insufficient_panelists do
    Interview.interviews_with_insufficient_panelists
    |> preload([:interview_type, candidate: [:role,:skills]])
    |> order_by(asc: :start_time)
    |> Interview.within_date_range(Date.now, Date.beginning_of_day(Date.now) |> Date.shift(days: 2))
    |> select([i], {i, fragment("( select (select max_sign_up_limit from interview_types where id = ?) - (select count(interview_id) from interview_panelists where interview_id = ?) as no_of_signups_needed)", i.interview_type_id, i.id)})
    |> Repo.all
  end

  defp construct_view_data(interviews) do
    Enum.map(interviews, fn({interview, count_of_panelists_required}) ->
      %{candidate: interview.candidate |> Candidate.format, count_of_panelists_required: count_of_panelists_required}
      |> Map.merge(interview |> Interview.format("%d/%m/%y %H:%M"))
    end)
    |> Enum.sort_by(fn (row) -> row.candidate.role end)
  end
end
