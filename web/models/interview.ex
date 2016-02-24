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

  # TODO: Move into InterviewPanelist model
  def get_candidate_ids_interviewed_by(panelist_login_name) do
    from ip in InterviewPanelist,
      where: ip.panelist_login_name == ^panelist_login_name,
      join: i in assoc(ip, :interview),
      group_by: i.candidate_id,
      select: i.candidate_id
  end

  def get_start_time_for_my_interviews(panelist_login_name) do
    from ip in InterviewPanelist,
      where: ip.panelist_login_name == ^panelist_login_name,
      join: i in assoc(ip, :interview),
      select: i.start_time
  end

  def get_interviews_with_associated_data do
    (from i in __MODULE__,
      join: c in assoc(i, :candidate),
      join: cs in assoc(c, :candidate_skills),
      preload: [:interview_panelist, candidate: {c, [candidate_skills: cs]}],
      select: i) |> default_order
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
      new_time = Changeset.get_field(existing_changeset, field)
      current_time = (Date.now |> Date.shift(mins: -5))
      valid = TimexHelper.compare(new_time, current_time)
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
    candidate_ids_interviewed = get_candidate_ids_interviewed_by(panelist_login_name) |> Repo.all
    my_previous_sign_up_start_times = get_start_time_for_my_interviews(panelist_login_name) |> Repo.all
    signup_counts = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all
    Enum.map(interviews, fn(interview) ->
      signup_eligiblity = interview |> signup(candidate_ids_interviewed, signup_counts, my_previous_sign_up_start_times)
      Map.put(interview, :signup, signup_eligiblity)
    end)
  end

  def validate_with_other_rounds(existing_changeset, interview_type \\ :empty) do
    if existing_changeset.valid? do
      new_time = Changeset.get_field(existing_changeset, :start_time)
      candidate_id = Changeset.get_field(existing_changeset, :candidate_id)
      current_priority = get_current_priority(existing_changeset, interview_type)
      previous_interview = get_interview(candidate_id, current_priority - 1)
      next_interview = get_interview(candidate_id, current_priority + 1);

      error_message = ""
      result = case {previous_interview, next_interview} do
        {nil, nil} -> 1
        {nil, next_interview} ->
          error_message = error_message <> "should be before #{next_interview.interview_type.name} atleast by 1 hour"
          TimexHelper.compare((next_interview.start_time |> Date.shift(hours: -1)), new_time)
        {previous_interview, nil} ->
          error_message = error_message <> "should be after #{previous_interview.interview_type.name} atleast by 1 hour"
          TimexHelper.compare(new_time, (previous_interview.start_time |> Date.shift(hours: 1)))
        {previous_interview, next_interview} ->
          error_message = error_message <> "should be after #{previous_interview.interview_type.name} and before #{next_interview.interview_type.name} atleast by 1 hour"
          # TODO: Remove magic numbers - move it into a 'end_time' column at the db-level
          TimexHelper.compare((next_interview.start_time |> Date.shift(hours: -1)), new_time) && TimexHelper.compare(new_time, (previous_interview.start_time |> Date.shift(hours: 1)))
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

  require Logger

  # TODO: Should this be added as a validation?
  defp signup(model, candidate_ids_interviewed, signup_counts, my_sign_up_start_times) do
    has_panelist_not_interviewed_candidate_value = has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed)
    is_signup_lesser_than_max_count_value = is_signup_lesser_than_max_count(model.id, signup_counts)
    is_not_completed_value = is_not_completed(model)
    is_within_time_buffer_of_my_previous_sign_ups_value = is_within_time_buffer_of_my_previous_sign_ups(model, my_sign_up_start_times)

    Logger.info('candidate_id:#{model.candidate_id}')
    Logger.info('has_panelist_not_interviewed_candidate:#{has_panelist_not_interviewed_candidate_value}')
    Logger.info('is_signup_lesser_than_max_count:#{is_signup_lesser_than_max_count_value}')
    Logger.info('is_not_complete:#{is_not_completed_value}')
    Logger.info('is_within_time_buffer_of_my_previous_sign_ups:#{is_within_time_buffer_of_my_previous_sign_ups_value}')

    has_panelist_not_interviewed_candidate_value
      and is_signup_lesser_than_max_count_value
      and is_not_completed_value
      and is_within_time_buffer_of_my_previous_sign_ups_value
  end

  def is_within_time_buffer_of_my_previous_sign_ups(model, my_sign_up_start_times) do
    Enum.all?(my_sign_up_start_times, fn(sign_up_start_time) ->
      abs(Date.diff(model.start_time, sign_up_start_time, :hours)) >= @time_buffer_between_sign_ups
    end)
  end

  def is_not_completed(model) do
    is_nil(model.interview_status_id)
  end

  def has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed) do
    !Enum.member?(candidate_ids_interviewed, model.candidate_id)
  end

  def is_signup_lesser_than_max_count(model_id, signup_counts) do
    result = Enum.filter(signup_counts, fn(i) -> i.interview_id == model_id end)
    result == [] or List.first(result).signup_count < @max_count
  end

  def update_status(id, status_id) do
    interview = id |> retrieve_interview
    if !is_nil(interview) do
     [changeset(interview, %{"interview_status_id": status_id})] |> ChangesetManipulator.updateChangesets
     if is_pass(status_id), do: delete_successive_interviews_and_panelists(interview.candidate_id, interview.start_time)
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

  # TODO: This doesn't handle the case where the Leadership and P3 have the same priority
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
end
