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
  alias RecruitxBackend.Repo
  alias RecruitxBackend.TimexHelper
  alias Timex.Date

  import Ecto.Query

  require Logger

  @max_count 2
  # TODO: Move the magic number (2) into the db
  @duration_of_interview 1
  @time_buffer_between_sign_ups 2

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

  def time_buffer_between_sign_ups, do: @time_buffer_between_sign_ups

  def now_or_in_next_seven_days(query) do
    start_of_today = Date.set(Date.now, time: {0, 0, 0})
    from i in query, where: i.start_time >= ^start_of_today and i.start_time <= ^(start_of_today |> Date.shift(days: 7))
  end

  def default_order(query) do
    from i in query, order_by: [asc: i.start_time, asc: i.id]
  end

  def descending_order(query) do
    from i in query, order_by: [desc: i.start_time, asc: i.id]
  end

  def get_interviews_with_associated_data do
    (from i in __MODULE__,
      join: c in assoc(i, :candidate),
      join: cs in assoc(c, :candidate_skills),
      preload: [:interview_panelist, candidate: {c, [candidate_skills: cs]}],
      select: i)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:interview_type_id, name: :candidate_interview_type_id_index)
    |> validate_single_update_of_status()
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:interview_type)
    |> assoc_constraint(:interview_status)
    |> is_in_future(:start_time)
    |> calculate_end_time
  end

  #TODO: When end_time is sent from UI, validations on end time to be done
  defp calculate_end_time(existing_changeset) do
    incoming_start_time = existing_changeset |> get_field(:start_time)
    if is_nil(existing_changeset.errors[:start_time]) and !is_nil(existing_changeset.changes[:start_time]) do
      min_valid_end_time = incoming_start_time |> Date.shift(hours: @duration_of_interview)
      existing_changeset = existing_changeset |> put_change(:end_time, min_valid_end_time)
    end
    existing_changeset
  end

  def is_in_future(existing_changeset, field) do
    if is_nil(existing_changeset.errors[:start_time]) and !is_nil(existing_changeset.changes[:start_time]) do
      new_start_time = Changeset.get_field(existing_changeset, field)
      current_time = (Date.now |> Date.shift(mins: -5))
      valid = TimexHelper.compare(new_start_time, current_time)
      if !valid, do: existing_changeset = Changeset.add_error(existing_changeset, field, "should be in the future")
    end
    existing_changeset
  end

  defp validate_single_update_of_status(existing_changeset) do
    id = get_field(existing_changeset, :id)
    if !is_nil(id) and is_nil(existing_changeset.errors[:interview_status_id]) do
      interview = id |> retrieve_interview
      if !is_nil(interview) and !is_nil(interview.interview_status_id), do: existing_changeset = add_error(existing_changeset, :interview_status, "Feedback has already been entered")
    end
    existing_changeset
  end

  def add_signup_eligibity_for(interviews, panelist_login_name) do
    {candidate_ids_interviewed, my_previous_sign_up_start_times} = InterviewPanelist.get_candidate_ids_and_start_times_interviewed_by(panelist_login_name)
    signup_counts = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all
    Enum.map(interviews, fn(interview) ->
      Logger.info("candidate_id:#{interview.candidate_id}")
      changeset_if_signup = InterviewPanelist.changeset(%InterviewPanelist{},
        %{panelist_login_name: panelist_login_name,
          interview_id: interview.id,
          candidate_ids_interviewed: candidate_ids_interviewed,
          my_previous_sign_up_start_times: my_previous_sign_up_start_times,
          signup_counts: signup_counts,
          interview: interview})
      signup_eligiblity = changeset_if_signup.valid?
      Map.put(interview, :signup, signup_eligiblity)
    end)
  end

  @lint [{Credo.Check.Refactor.ABCSize, false}, {Credo.Check.Refactor.CyclomaticComplexity, false}]
  def validate_with_other_rounds(existing_changeset, interview_type \\ :empty) do
    if existing_changeset.valid? do
      new_start_time = Changeset.get_field(existing_changeset, :start_time)
      new_end_time = Changeset.get_field(existing_changeset, :end_time)
      candidate_id = Changeset.get_field(existing_changeset, :candidate_id)
      interview_id = Changeset.get_field(existing_changeset, :id)
      current_priority = get_current_priority(existing_changeset, interview_type)
      previous_interview = get_interview(candidate_id, current_priority - 1)
      next_interview = get_interview(candidate_id, current_priority + 1)
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

  def is_within_time_buffer_of_my_previous_sign_ups(model, my_sign_up_start_times) do
    is_within_time_buffer_of_my_previous_sign_ups_value = Enum.all?(my_sign_up_start_times, fn(sign_up_start_time) ->
      abs(Date.diff(model.start_time, sign_up_start_time, :hours)) >= @time_buffer_between_sign_ups
    end)
    Logger.info('is_within_time_buffer_of_my_previous_sign_ups:#{is_within_time_buffer_of_my_previous_sign_ups_value}')
    is_within_time_buffer_of_my_previous_sign_ups_value
  end

  def has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed) do
    has_panelist_not_interviewed_candidate_value = !Enum.member?(candidate_ids_interviewed, model.candidate_id)
    Logger.info('has_panelist_not_interviewed_candidate:#{has_panelist_not_interviewed_candidate_value}')
    has_panelist_not_interviewed_candidate_value
  end

  def is_not_completed(model) do
    is_not_completed_value = is_nil(model.interview_status_id)
    Logger.info('is_not_complete:#{is_not_completed_value}')
    is_not_completed_value
  end

  def is_signup_lesser_than_max_count(model_id, signup_counts) do
    result = Enum.filter(signup_counts, fn(i) -> i.interview_id == model_id end)
    is_signup_lesser_than_max_count_value = result == [] or List.first(result).signup_count < @max_count
    Logger.info('is_signup_lesser_than_max_count:#{is_signup_lesser_than_max_count_value}')
    is_signup_lesser_than_max_count_value
  end

  def update_status(id, status_id) do
    interview = id |> retrieve_interview
    if !is_nil(interview) do
     [changeset(interview, %{"interview_status_id": status_id})] |> ChangesetManipulator.updateChangesets
     if is_pass(status_id) do
       delete_successive_interviews_and_panelists(interview.candidate_id, interview.start_time)
       Candidate.updateCandidateStatusAsPass(interview.candidate_id)
     end
    end
  end

  defp is_pass(status_id) do
    # TODO: Use a constant defined in InterviewStatus instead of hardcoding a magic string
    status = (from i in InterviewStatus, where: i.name == "Pass") |> Repo.one
    !is_nil(status) and status.id == status_id
  end

  def delete_successive_interviews_and_panelists(candidate_id, start_time) do
    (from i in __MODULE__,
      where: i.candidate_id == ^candidate_id,
      where: (i.start_time > ^start_time)) |> Repo.delete_all
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
end
