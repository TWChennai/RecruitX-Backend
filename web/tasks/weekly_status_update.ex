defmodule RecruitxBackend.WeeklyStatusUpdate do
  import Ecto.Query

  alias MailmanExtensions.Mailer
  alias MailmanExtensions.Templates
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo
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
    summary = candidates |> construct_summary_data
    {:ok, start_date} = Date.now |> Date.shift(days: -5) |> DateFormat.format("{D}/{M}/{YY}")
    {:ok, to_date} = Date.now |> Date.shift(days: -1) |> DateFormat.format("{D}/{M}/{YY}")
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
    %{
      candidates_appeared: Enum.count(candidates),
      interviews_count: candidates |> get_total_no_of_interviews,
      candidates_in_progress: Candidate.get_total_no_of_candidates_in_progress,
      candidates_pursued: Enum.count(Candidate.get_all_candidates_pursued_after_pipeline_closure),
      candidates_rejected: get_total_no_of_rejects
    }
  end

  defp get_total_no_of_rejects() do
    end_date = Date.set(Date.now, time: {0, 0, 0}) |> Date.shift(days: -1)
    start_date = end_date |> Date.shift(days: -4)
    Enum.count(Candidate.get_pass_candidates_within_range(start_date, end_date)) + Enum.count(Candidate.get_all_candidates_rejected_after_pipeline_closure)
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
