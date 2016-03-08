defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo

  import Ecto.Query, only: [where: 2, from: 2]

  @max_count 2

  schema "interview_panelists" do
    field :panelist_login_name, :string

    belongs_to :interview, Interview

    timestamps
  end

  def get_interviews_for(panelist_login_name) do
    from ip in __MODULE__,
      where: ip.panelist_login_name == ^panelist_login_name,
      join: i in assoc(ip, :interview),
      select: {i.candidate_id, i.start_time}
  end

  def get_interview_type_based_count_of_sign_ups do
    from ip in __MODULE__,
      join: i in assoc(ip, :interview),
      group_by: ip.interview_id,
      group_by: i.interview_type_id,
      select: %{"interview_id": ip.interview_id, "signup_count": count(ip.interview_id), "interview_type": i.interview_type_id}
  end

  def get_signup_count_for_interview_id(id) do
    from ip in __MODULE__,
      where: ip.interview_id == ^id,
      group_by: ip.interview_id,
      select: count(ip.interview_id)
  end

  @required_fields ~w(panelist_login_name interview_id)
  @optional_fields ~w()

  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_format(:panelist_login_name, AppConstants.name_format)
    |> validate_sign_up_for_interview(params)
    |> unique_constraint(:panelist_login_name, name: :interview_panelist_login_name_index, message: "You have already signed up for this interview")
    |> assoc_constraint(:interview, message: "Interview does not exist")
  end

  #TODO:'You have already signed up for the same interview' constraint error never occurs as it is handled here at changeset level itself
  defp validate_sign_up_for_interview(existing_changeset, %{candidate_ids_interviewed: candidate_ids_interviewed, my_previous_sign_up_start_times: my_previous_sign_up_start_times, interview: interview, signup_counts: signup_counts})
    when not(is_nil(candidate_ids_interviewed)) and not(is_nil(my_previous_sign_up_start_times)) and not(is_nil(interview))  and not(is_nil(signup_counts)) do
      existing_changeset
      |> validate_panelist_has_not_interviewed_candidate(candidate_ids_interviewed, interview)
      |> validate_panelist_has_no_other_interview_within_time_buffer(interview, my_previous_sign_up_start_times)
      |> validate_interview_is_not_over(interview)
      |> validate_signup_count(signup_counts, interview.id)
  end

  defp validate_sign_up_for_interview(existing_changeset, _) do
    interview_id = get_field(existing_changeset, :interview_id)
    panelist_login_name = get_field(existing_changeset, :panelist_login_name)
    if check_not_nil([interview_id, panelist_login_name]) do
      interview = Interview |> Repo.get(interview_id)
      if !is_nil(interview) do
        {candidate_ids_interviewed, my_sign_up_start_times} = get_candidate_ids_and_start_times_interviewed_by(panelist_login_name)
        signup_counts = __MODULE__.get_interview_type_based_count_of_sign_ups |> where(interview_id: ^interview.id) |> Repo.all
        existing_changeset = validate_sign_up_for_interview(existing_changeset, %{panelist_login_name: panelist_login_name,
          candidate_ids_interviewed: candidate_ids_interviewed,
          my_previous_sign_up_start_times: my_sign_up_start_times,
          interview: interview,
          signup_counts: signup_counts})
      end
    end
    existing_changeset
  end

  defp validate_panelist_has_not_interviewed_candidate(existing_changeset, candidate_ids_interviewed, interview) do
    if existing_changeset.valid? and !Interview.has_panelist_not_interviewed_candidate(interview, candidate_ids_interviewed), do: existing_changeset = add_error(existing_changeset, :signup, "You have already signed up an interview for this candidate")
    existing_changeset
  end

  defp validate_panelist_has_no_other_interview_within_time_buffer(existing_changeset, interview, my_previous_sign_up_start_times) do
    if existing_changeset.valid? and !Interview.is_within_time_buffer_of_my_previous_sign_ups(interview, my_previous_sign_up_start_times), do: existing_changeset = add_error(existing_changeset, :signup, "You are already signed up for another interview within #{Interview.time_buffer_between_sign_ups} hours")
    existing_changeset
  end

  defp validate_interview_is_not_over(existing_changeset, interview) do
    if existing_changeset.valid? and !Interview.is_not_completed(interview),do: existing_changeset = add_error(existing_changeset, :signup, "Interview is already over!")
    existing_changeset
  end

  defp validate_signup_count(existing_changeset, signup_counts, interview_id) do
    if existing_changeset.valid? and !Interview.is_signup_lesser_than_max_count(interview_id, signup_counts), do: existing_changeset = add_error(existing_changeset, :signup_count, "More than #{@max_count} signups are not allowed")
    existing_changeset
  end

  def get_candidate_ids_and_start_times_interviewed_by(panelist_login_name) do
    query_result = get_interviews_for(panelist_login_name) |> Repo.all
    map_result = Enum.reduce(query_result, %{},fn(x,acc) ->  Map.merge(acc,%{elem(x,0) => elem(x,1)}) end)
    {Map.keys(map_result), Map.values(map_result)}
  end

  defp check_not_nil(enumerable) do
    Enum.all?(enumerable, fn(x) -> !is_nil(x) end)
  end
end
