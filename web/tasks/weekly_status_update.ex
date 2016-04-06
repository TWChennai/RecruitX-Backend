defmodule RecruitxBackend.WeeklyStatusUpdate do
  import Ecto.Query
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias MailmanExtensions.Templates
  alias MailmanExtensions.Mailer
  alias Timex.Date
  alias Timex.DateFormat

  def execute do
    query = Interview |> Interview.now_or_in_previous_five_days |> preload([:interview_panelist, :interview_status, :interview_type])
    candidates_weekly_status = Candidate
                                |> preload([:role, interviews: ^query])
                                |> order_by(asc: :role_id)
                                |> Repo.all
    candidates = candidates_weekly_status
    |> filter_out_candidates_without_interviews
    |> construct_view_data
    {:ok, start_date} = Date.now |> Date.shift(days: -5) |> DateFormat.format("{D}/{M}/{YY}")
    {:ok, to_date} = Date.now |> Date.shift(days: -1) |> DateFormat.format("{D}/{M}/{YY}")
    email_content = if candidates != [], do: Templates.weekly_status_update(start_date, to_date, candidates),
                    else: Templates.weekly_status_update_default(start_date, to_date)
    Mailer.deliver(%{
      subject: "[RecruitX] Weekly Status Update",
      # TODO: get actual TW_CHENNAI_RECRUITMENT_TEAM_EMAIL_ADDRESS in environment variable
      to: [System.get_env("TW_CHENNAI_RECRUITMENT_TEAM_EMAIL_ADDRESS")],
      html: email_content
    })
  end

  def construct_view_data(candidates_weekly_status) do
    Enum.map(candidates_weekly_status, fn(candidate) -> %{
      name: candidate.first_name <> " " <> candidate.last_name,
      role: candidate.role.name,
      interviews: Candidate.get_formatted_interviews_with_result(candidate),
    }
    end)
  end

  def filter_out_candidates_without_interviews(candidates_weekly_status) do
    Enum.filter(candidates_weekly_status, fn(candidate)-> candidate.interviews != []  end)
  end
end
