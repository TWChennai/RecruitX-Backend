defmodule RecruitxBackend.StatusUpdate do
  import Ecto.Query

  alias RecruitxBackend.MailHelper
  alias Swoosh.Templates
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.TimeRange
  alias RecruitxBackend.Repo
  alias Timex.DateFormat
  alias Timex.Date

  def execute_weekly do
    execute(TimeRange.get_previous_week, "Weekly")
  end

  def execute_monthly do
    execute(TimeRange.get_previous_month, "Monthly")
  end

  def execute_quarterly do
   execute(TimeRange.get_previous_quarter, "Quarterly")
  end

  defp execute(%{starting: starting, ending: ending} = time_range, period_name) do
    query = Interview |> Interview.within_date_range(starting, ending) |> preload([:interview_panelist, :interview_status, :interview_type])
    candidates_status = Candidate
                                |> preload([:role, interviews: ^query])
                                |> order_by(asc: :role_id)
                                |> Repo.all

    candidates = candidates_status
                  |> filter_out_candidates_without_interviews
                  |> construct_view_data
    summary = candidates |> construct_summary_data(time_range)
    {:ok, start_date} = starting |> DateFormat.format("{D}/{M}/{YY}")
    {:ok, to_date} = ending |> DateFormat.format("{D}/{M}/{YY}")
    email_content = if candidates != [], do: Templates.status_update(start_date, to_date, candidates, summary),
                    else: Templates.status_update_default(start_date, to_date)

    MailHelper.deliver(%{
      subject: "[RecruitX] "<> period_name <>" Status Update",
      to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
      html_body: email_content
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

  defp construct_summary_data(candidates, date_range) do
    {candidates_pursued, candidates_rejected} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(date_range)
    %{
      candidates_appeared: Enum.count(candidates),
      interviews_count: candidates |> get_total_no_of_interviews,
      candidates_in_progress: Candidate.get_total_no_of_candidates_in_progress,
      candidates_pursued: Enum.count(candidates_pursued),
      candidates_rejected: get_total_no_of_rejects(candidates_rejected, date_range)
    }
  end

  defp get_total_no_of_rejects(candidates_rejected, date_range) do
    Candidate.get_no_of_pass_candidates_within_range(date_range) + Enum.count(candidates_rejected)
  end

  defp get_total_no_of_interviews(candidates) do
    Enum.reduce(candidates, 0, fn(candidate, acc) ->
      Enum.count(candidate.interviews) + acc
    end)
  end

  def filter_out_candidates_without_interviews(candidates_status) do
    Enum.filter(candidates_status, fn(candidate)-> candidate.interviews != []  end)
  end
end
