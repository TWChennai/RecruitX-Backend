defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SignUpEvaluator

  import Ecto.Query, only: [where: 2, from: 2]

  @max_count 2
  # TODO: Move the magic number (2) into the db

  def max_count, do: @max_count

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
    |> validate_panelist_experience(params)
    |> validate_sign_up_for_interview(params)
    |> unique_constraint(:panelist_login_name, name: :interview_panelist_login_name_index, message: "You have already signed up for this interview")
    |> assoc_constraint(:interview, message: "Interview does not exist")
  end

  defp validate_panelist_experience(existing_changeset, %{"panelist_experience" => panelist_experience}) do
    if existing_changeset.valid? and panelist_experience |> is_nil, do: existing_changeset = add_error(existing_changeset, :panelist_experience, "can't be blank")
    existing_changeset
  end

  defp validate_panelist_experience(existing_changeset, %{"sign_up_data_container" => %{"experience_eligibility_criteria" => %{"panelist_experience" => panelist_experience}}}) do
    if existing_changeset.valid? and panelist_experience |> is_nil, do: existing_changeset = add_error(existing_changeset, :panelist_experience, "can't be blank")
    existing_changeset
  end

  defp validate_panelist_experience(existing_changeset, params) do
    if existing_changeset.valid? do
      existing_changeset = add_error(existing_changeset, :panelist_experience, "can't be blank")
    end
    existing_changeset
  end

  #TODO:'You have already signed up for the same interview' constraint error never occurs as it is handled here at changeset level itself
  defp validate_sign_up_for_interview(existing_changeset, %{interview: interview, sign_up_data_container: sign_up_data_container})
    when not(is_nil(interview)) and not(is_nil(sign_up_data_container)) do
      sign_up_evaluation_status = SignUpEvaluator.evaluate(sign_up_data_container, interview)
      existing_changeset |> update_changeset(sign_up_evaluation_status)
  end

  defp validate_sign_up_for_interview(existing_changeset, params) do
    interview_id = get_field(existing_changeset, :interview_id)
    panelist_login_name = get_field(existing_changeset, :panelist_login_name)
    panelist_experience = params["panelist_experience"]
    if existing_changeset.valid? do
      interview = (Interview) |> Repo.get(interview_id)
      if !is_nil(interview) do
        sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(panelist_login_name, Decimal.new(panelist_experience))
        existing_changeset = validate_sign_up_for_interview(existing_changeset, %{interview: interview, sign_up_data_container: sign_up_data_container})
      end
    end
    existing_changeset
  end

  defp update_changeset(existing_changeset, sign_up_evaluation_status) do
    if !sign_up_evaluation_status.valid? do
      existing_changeset = Enum.reduce(sign_up_evaluation_status.errors, existing_changeset, fn({field_name, description}, acc) ->
        add_error(acc, field_name, description)
      end)
    end
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
