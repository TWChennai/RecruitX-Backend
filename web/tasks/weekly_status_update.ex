defmodule RecruitxBackend.WeeklyStatusUpdate do
  import Ecto.Query

  alias MailmanExtensions.Mailer
  alias MailmanExtensions.Templates
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.PreviousWeek
  alias RecruitxBackend.Repo
  alias Timex.DateFormat

  @previous_week PreviousWeek.get

  def execute do
    query = Interview |> Interview.working_days_in_current_week |> preload([:interview_panelist, :interview_status, :interview_type])
    candidates_weekly_status = Candidate
                                |> preload([:role, interviews: ^query])
                                |> order_by(asc: :role_id)
                                |> Repo.all
    candidates = candidates_weekly_status
                  |> filter_out_candidates_without_interviews
                  |> construct_view_data
    summary = candidates |> construct_summary_data
    {:ok, start_date} = @previous_week.starting |> DateFormat.format("{D}/{M}/{YY}")
    {:ok, to_date} = @previous_week.ending |> DateFormat.format("{D}/{M}/{YY}")
    email_content = if candidates != [], do: Templates.weekly_status_update(start_date, to_date, candidates, summary),
                    else: Templates.weekly_status_update_default(start_date, to_date)
    Mailer.deliver(%{
      subject: "[RecruitX] Weekly Status Update",
      to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
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

  defp construct_summary_data(candidates) do
    {candidates_pursued, candidates_rejected} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(@previous_week)
    %{
      candidates_appeared: Enum.count(candidates),
      interviews_count: candidates |> get_total_no_of_interviews,
      candidates_in_progress: Candidate.get_total_no_of_candidates_in_progress,
      candidates_pursued: Enum.count(candidates_pursued),
      candidates_rejected: get_total_no_of_rejects(candidates_rejected)
    }
  end

  defp get_total_no_of_rejects(candidates_rejected) do
    Candidate.get_no_of_pass_candidates_within_range(@previous_week) + Enum.count(candidates_rejected)
  end

  defp get_total_no_of_interviews(candidates) do
    Enum.reduce(candidates, 0, fn(candidate, acc) ->
      Enum.count(candidate.interviews) + acc
    end)
  end

  def filter_out_candidates_without_interviews(candidates_weekly_status) do
    Enum.filter(candidates_weekly_status, fn(candidate)-> candidate.interviews != []  end)
  end
end
