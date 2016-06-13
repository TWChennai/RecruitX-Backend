defmodule RecruitxBackend.StatusUpdate do
  import Ecto.Query

  alias RecruitxBackend.MailHelper
  alias Swoosh.Templates
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Timer
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Panel
  alias RecruitxBackend.Role
  alias Timex.DateFormat

  def execute_weekly do
    execute(Timer.get_previous_week, "Weekly", System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES"), false)
  end

  def execute_monthly do
    time = Timer.get_previous_month
    {:ok, subject_suffix} = DateFormat.format(time.starting, " - %b %Y", :strftime)
    execute(time, "Monthly", System.get_env("MONTHLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES"), true, subject_suffix)
  end

  def execute_quarterly do
    time = Timer.get_previous_quarter
    subject_suffix = " - Q" <> to_string(div(time.starting.month + 2, 4) + 1) <> " " <> to_string(time.starting.year)
    execute(time, "Quarterly", System.get_env("QUARTERLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES"), true, subject_suffix)
  end

  defp execute(%{starting: starting, ending: ending} = time_range, period_name, recepient, exclude_details, subject_suffix \\ "") do
    query = Interview |> Panel.within_date_range(starting, ending) |> preload([:interview_panelist, :interview_status, :interview_type]) |> order_by(asc: :interview_type_id)
    candidates_status = Candidate
                                |> preload([:role, interviews: ^query])
                                |> order_by(asc: :role_id)
                                |> Repo.all

    candidates = candidates_status
                  |> filter_out_candidates_without_interviews
                  |> construct_view_data
    summary = Role.get_all_roles()
      |> Enum.reduce(%{}, fn role, acc -> Map.put(acc, role.name, construct_summary_data(Enum.filter(candidates, fn x -> x.role == role.name end), time_range, role.id)) end)
    {:ok, start_date} = starting |> DateFormat.format("{D}/{M}/{YY}")
    {:ok, to_date} = ending |> DateFormat.format("{D}/{M}/{YY}")
    email_content = if candidates != [], do: Templates.status_update(start_date, to_date, summary, exclude_details),
                    else: Templates.status_update_default(start_date, to_date)

    MailHelper.deliver(%{
      subject: "[RecruitX] " <> period_name <> " Status Update" <> subject_suffix,
      to: recepient |> String.split,
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

  defp construct_summary_data(candidates, date_range, role_id) do
    {candidates_pursued, candidates_rejected} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(date_range, role_id)
    %{
      candidates_appeared: Enum.count(candidates),
      interviews_count: candidates |> get_total_no_of_interviews,
      candidates_in_progress: Candidate.get_total_no_of_candidates_in_progress(role_id),
      candidates_pursued: Enum.count(candidates_pursued),
      candidates_rejected: get_total_no_of_rejects(candidates_rejected, date_range, role_id),
      candidates: candidates
    }
  end

  defp get_total_no_of_rejects(candidates_rejected, date_range, role_id) do
    Candidate.get_no_of_pass_candidates_within_range(date_range, role_id) + Enum.count(candidates_rejected)
  end

  defp get_total_no_of_interviews(candidates) do
    Enum.reduce(candidates, 0, fn(candidate, acc) ->
      Enum.count(candidate.interviews) + acc
    end)
  end

  def filter_out_candidates_without_interviews(candidates_status) do
    Enum.filter(candidates_status, fn(candidate) -> candidate.interviews != []  end)
  end
end
