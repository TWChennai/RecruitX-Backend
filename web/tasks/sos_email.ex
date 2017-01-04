defmodule RecruitxBackend.SosEmail do
  import Ecto.Query, only: [preload: 2, order_by: 2, select: 3]

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Panel
  alias RecruitxBackend.Repo
  alias RecruitxBackend.TimexHelper
  alias Swoosh.Templates

  def execute do
    interviews_with_insufficient_panelists = get_interviews_with_insufficient_panelists() |> construct_view_data

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
    |> Panel.within_date_range(TimexHelper.utc_now(), TimexHelper.beginning_of_day(TimexHelper.utc_now()) |> TimexHelper.add(2, :days))
    # TODO: Try to move away from prepared statements/fragments, and instead use first-class functions defined by Ecto
    # This will make upgrades much easier in the future.
    |> select([i], {i, fragment("(select (select max_sign_up_limit from interview_types where id = ?) - (select count(interview_id) from interview_panelists where interview_id = ?) as no_of_signups_needed)", i.interview_type_id, i.id)})
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
