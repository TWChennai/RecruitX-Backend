defmodule RecruitxBackend.Interview do

  use RecruitxBackend.Web, :model

  alias Ecto.Changeset
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.ChangesetManipulator
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Repo
  alias RecruitxBackend.RoleInterviewType
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.Panel
  alias Timex.Date
  alias Timex.DateFormat
  alias RecruitxBackend.Timer
  alias RecruitxBackend.InterviewCancellationNotification

  import Ecto.Query

  @duration_of_interview 1  # in hours

  schema "interviews" do
    field :start_time, Timex.Ecto.DateTime
    field :end_time, Timex.Ecto.DateTime
    belongs_to :candidate, Candidate
    belongs_to :interview_type, InterviewType
    belongs_to :interview_status, InterviewStatus

    timestamps

    has_many :interview_panelist, InterviewPanelist
    has_many :feedback_images, FeedbackImage
  end

  @required_fields ~w(candidate_id interview_type_id start_time)
  @optional_fields ~w(interview_status_id)

  def tuesday_to_friday_of_the_current_week(query) do
    start_of_tuesday = Date.now |> Date.beginning_of_week(:mon) |> Date.shift(days: 1)
    end_of_friday = start_of_tuesday |> Date.shift(days: 4)
    Panel.within_date_range(query, start_of_tuesday, end_of_friday)
  end

  def working_days_in_current_week(model) do
    %{starting: starting, ending: ending} =  Timer.get_previous_week
    Panel.within_date_range(model, starting, ending)
  end

  def get_interviews_with_associated_data do
    (from i in __MODULE__,
      preload: [:interview_panelist, candidate: :candidate_skills],
      select: i)
  end

  def get_last_completed_rounds_start_time_for(candidate_id) do
    interview_with_feedback_and_maximum_start_time =
                              (from i in __MODULE__,
                              where: i.candidate_id == ^candidate_id and
                              not(is_nil(i.interview_status_id)),
                              order_by: [desc: i.start_time],
                              limit: 1)
                              |> Repo.one
    case interview_with_feedback_and_maximum_start_time do
      nil -> Date.set(Date.epoch, date: {0, 0, 1})
      _ -> interview_with_feedback_and_maximum_start_time.start_time
    end
  end

  def get_last_completed_rounds_status_for(candidate_id, interview_start_time) do
    no_of_interviews_with_no_feedback =
                              (from i in __MODULE__,
                              where: i.candidate_id == ^candidate_id and
                              is_nil(i.interview_status_id) and
                              i.start_time < ^ interview_start_time,
                              select: count(i.id)
                              )
                              |> Repo.one
    case no_of_interviews_with_no_feedback do
      0 -> true
      _ -> false
    end
  end

  def get_candidates_with_all_rounds_completed do
    (from i in __MODULE__,
      group_by: i.candidate_id,
      select: [i.candidate_id, max(i.start_time), count(i.candidate_id)])
  end

  def interviews_with_insufficient_panelists do
    __MODULE__
    |> join(:left, [i], ip in assoc(i, :interview_panelist))
    |> group_by([i], i.id)
    # TODO: Try to move away from prepared statements/fragments, and instead use first-class functions defined by Ecto
    # This will make upgrades much easier in the future.
    |> having([i], count(i.id) < fragment("(select max_sign_up_limit from interview_types where id = ?)", i.interview_type_id) or not(i.id in fragment("(select interview_id from interview_panelists where interview_id = ?)", i.id)))
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:interview_type_id, name: :candidate_interview_type_id_index)
    |> validate_single_update_of_status()
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:interview_type)
    |> assoc_constraint(:interview_status)
    |> Timer.is_in_future(:start_time)
    |> Timer.is_less_than_a_month(:start_time)
    |> Timer.add_end_time(@duration_of_interview)
  end

  def get_interviews_ordered_by_start_time do
    from i in __MODULE__,
    preload: [:interview_type, :interview_panelist, :interview_status, :feedback_images],
    order_by: [i.start_time]
  end

  defp validate_single_update_of_status(existing_changeset) do
    id = get_field(existing_changeset, :id)
    if !is_nil(id) and is_nil(existing_changeset.errors[:interview_status_id]) do
      interview = id |> retrieve_interview
      if !is_nil(interview) and !is_nil(interview.interview_status_id), do: existing_changeset = add_error(existing_changeset, :interview_status, "Feedback has already been entered")
    end
    existing_changeset
  end

  defp get_max_and_min_priority do
    (from it in InterviewType,
    select: {max(it.priority), min(it.priority)}) |> Repo.one
  end

  defp get_previous_interview(_candidate_id, priority, min_priority) when priority < min_priority, do: nil

  defp get_previous_interview(candidate_id, priority, min_priority) do
    interview = get_interview(candidate_id, priority)
    case {interview, priority} do
      {nil, ^min_priority} -> nil
      {nil, _} -> get_previous_interview(candidate_id, priority - 1, min_priority)
      _ -> interview
    end
  end

  defp get_next_interview(_candidate_id, priority, max_priority) when priority > max_priority, do: nil

  defp get_next_interview(candidate_id, priority, max_priority) do
    interview = get_interview(candidate_id, priority)
    case {interview, priority} do
      {nil, ^max_priority} -> nil
      {nil, _} -> get_next_interview(candidate_id, priority + 1, max_priority)
      _ -> interview
    end
  end


  @lint [{Credo.Check.Refactor.ABCSize, false}, {Credo.Check.Refactor.CyclomaticComplexity, false}]
  def validate_with_other_rounds(existing_changeset, interview_type \\ :empty) do
    if existing_changeset.valid? do
      new_start_time = Changeset.get_field(existing_changeset, :start_time)
      new_end_time = Changeset.get_field(existing_changeset, :end_time)
      candidate_id = Changeset.get_field(existing_changeset, :candidate_id)
      interview_id = Changeset.get_field(existing_changeset, :id)
      current_priority = get_current_priority(existing_changeset, interview_type)
      {max_priority, min_priority} = get_max_and_min_priority
      previous_interview = get_previous_interview(candidate_id, current_priority - 1, min_priority)
      next_interview = get_next_interview(candidate_id, current_priority + 1, max_priority)
      interview_with_same_priority = case interview_id do
        nil -> get_interview(candidate_id, current_priority)
        _ -> get_interview(candidate_id, current_priority, interview_id)
      end

      # TODO: This can be made a lot simpler by just using
      # (1) (one array for interviews for all interview_types <= current priority - self) and from this find the latest one
      # (2) (one array for interviews for all interview_types >= current priority - self) and from this find the earliest one
      # (3) check for overlap between results of (1) and (2) in case of non-nil value
      error_message = ""
      result = case {previous_interview, next_interview, interview_with_same_priority} do
        {nil, nil, nil} -> 1
        {nil, next_interview, nil} ->
          error_message = error_message <> "should be before #{next_interview.interview_type.name} atleast by 1 hour"
          TimexHelper.compare(next_interview.start_time, new_end_time)
        {previous_interview, nil, nil} ->
          error_message = error_message <> "should be after #{previous_interview.interview_type.name} atleast by 1 hour"
          TimexHelper.compare(new_start_time, previous_interview.end_time)
        {previous_interview, next_interview, nil} ->
          error_message = error_message <> "should be after #{previous_interview.interview_type.name} and before #{next_interview.interview_type.name} atleast by 1 hour"
          TimexHelper.compare(next_interview.start_time, new_end_time) && TimexHelper.compare(new_start_time, previous_interview.end_time)
        {nil, nil, interview_with_same_priority} ->
          error_message = error_message <> "before/after #{interview_with_same_priority.interview_type.name} atleast by 1 hour"
          (TimexHelper.compare(interview_with_same_priority.start_time, new_end_time) || TimexHelper.compare(new_start_time, interview_with_same_priority.end_time))
        {nil, next_interview, interview_with_same_priority} ->
          error_message = error_message <> "should be before #{next_interview.interview_type.name} and before/after #{interview_with_same_priority.interview_type.name} atleast by 1 hour"
          (TimexHelper.compare(interview_with_same_priority.start_time, new_end_time) || TimexHelper.compare(new_start_time, interview_with_same_priority.end_time)) &&
          TimexHelper.compare(next_interview.start_time, new_end_time)
        {previous_interview, nil, interview_with_same_priority} ->
          error_message = error_message <> "should be after #{previous_interview.interview_type.name} and before/after #{interview_with_same_priority.interview_type.name} atleast by 1 hour"
          (TimexHelper.compare(interview_with_same_priority.start_time, new_end_time) || TimexHelper.compare(new_start_time, interview_with_same_priority.end_time)) && TimexHelper.compare(new_start_time, previous_interview.end_time)
        {previous_interview, next_interview, interview_with_same_priority} ->
          error_message = error_message <> "should be after #{previous_interview.interview_type.name}, before #{next_interview.interview_type.name} and before/after #{interview_with_same_priority.interview_type.name} atleast by 1 hour"
          (TimexHelper.compare(interview_with_same_priority.start_time, new_end_time) || TimexHelper.compare(new_start_time, interview_with_same_priority.end_time)) && TimexHelper.compare(new_start_time, previous_interview.send_time) && TimexHelper.compare(next_interview.start_time, new_end_time)
      end

      if !result, do: existing_changeset = Changeset.add_error(existing_changeset, :start_time, error_message)
    end
    existing_changeset
  end

  defp get_current_priority(changes, interview_type) do
    case interview_type do
      :empty -> (Changeset.get_field(changes, :interview_type)).priority
      _ -> interview_type.priority
    end
  end

  def is_not_completed(model) do
    is_nil(model.interview_status_id)
  end

  def update_status(id, status_id) do
    interview = id |> retrieve_interview
    if !is_nil(interview) do
      [changeset(interview, %{"interview_status_id": status_id})] |> ChangesetManipulator.validate_and(Repo.custom_update)
      if is_pass(status_id) do
        Repo.transaction fn ->
          delete_successive_interviews_and_panelists(interview.candidate_id, interview.start_time)
          Candidate.updateCandidateStatusAsPass(interview.candidate_id)
        end
      end
    end
  end

  defp is_pass(status_id) do
    status = (from i in InterviewStatus, where: i.name == ^PipelineStatus.pass) |> Repo.one
    !is_nil(status) and status.id == status_id
  end

  def delete_successive_interviews_and_panelists(candidate_id, start_time) do
    interviews_to_delete_query = from i in __MODULE__,
    where: i.candidate_id == ^candidate_id,
    where: (i.start_time > ^start_time)
    interviews_to_delete_query |> InterviewCancellationNotification.execute
    interviews_to_delete_query |> Repo.delete_all
  end

  defp retrieve_interview(id) do
    __MODULE__ |> Repo.get(id)
  end

  defp get_interview(candidate_id, priority) do
    (from i in __MODULE__,
      join: it in assoc(i, :interview_type),
      preload: [:interview_type],
      where: i.candidate_id == ^candidate_id and
      it.priority == ^priority,
      order_by: i.start_time,
      limit: 1)
    |> Repo.one
  end

  defp get_interview(candidate_id, priority, interview_id) do
    (from i in __MODULE__,
      join: it in assoc(i, :interview_type),
      preload: [:interview_type],
      where: i.candidate_id == ^candidate_id and
      it.priority == ^priority and
      i.id != ^interview_id,
      order_by: i.start_time,
      limit: 1)
    |> Repo.one
  end

  def get_first_interview_id_for_all_candidates do
    # TODO: Try to move away from prepared statements/fragments, and instead use first-class functions defined by Ecto
    # This will make upgrades much easier in the future.
    (from i in __MODULE__,
    where: i.id in fragment("select i.id from interviews i where i.candidate_id=? order by i.start_time limit 1", i.candidate_id), select: i.id)
    |> Repo.all
  end

  def get_last_interview_status_for(current_candidate, last_interviews_data) do
    total_no_of_interview_types = Enum.count(RoleInterviewType |> where([i], ^current_candidate.role_id == i.role_id) |> Repo.all)
    if Candidate.is_pipeline_closed(current_candidate) do
      result = Enum.filter(last_interviews_data, fn([candidate_id, _, _]) -> current_candidate.id == candidate_id end)
      case result do
        [[candidate_id, last_interview_start_time, number_of_interviews]] ->
          status_id = (from i in __MODULE__,
          where: i.start_time == ^last_interview_start_time and
          i.candidate_id == ^candidate_id ,
          select: i.interview_status_id)
          |> Repo.one
          if !is_pass(status_id) and total_no_of_interview_types != number_of_interviews, do: status_id = nil
          status_id
        [] -> nil
      end
    end
  end

  def format(interview) do
    %{
      name: interview.interview_type.name,
      date: DateFormat.format!(interview.start_time, "%b-%d", :strftime)
    }
  end

  def format(interview, date_format) do
    %{
      name: interview.interview_type.name,
      date: interview.start_time |> TimexHelper.format(date_format)
    }
  end

  def format_with_result_and_panelist(interview, date_format \\ "%d/%m/%y") do
    status = "Not Evaluated"
    if not(is_nil(interview.interview_status)), do: status = interview.interview_status.name
    %{
      name: interview.interview_type.name,
      date: interview.start_time |> TimexHelper.format(date_format),
      result: status,
      panelists: get_formatted_interview_panelists(interview)
    }
  end

  # TODO: Isn't there a simpler logic to join an array of strings?
  defp get_formatted_interview_panelists(interview) do
    if Enum.empty?(interview.interview_panelist) do
      "NA"
    else
      Enum.reduce(interview.interview_panelist, "", fn(panelist, accumulator) ->
        accumulator <> ", " <> panelist.panelist_login_name
      end)
      |> String.lstrip(?,)
      |> String.lstrip
    end
  end
end
