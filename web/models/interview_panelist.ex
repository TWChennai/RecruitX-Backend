defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.Team
  alias RecruitxBackend.PanelistDetails
  alias RecruitxBackend.SignUpEvaluator

  schema "interview_panelists" do
    field :panelist_login_name, :string
    field :satisfied_criteria, :string

    belongs_to :interview, Interview
    belongs_to :team, Team

    timestamps
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
  @optional_fields ~w(team_id)

  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_format(:panelist_login_name, AppConstants.name_format)
    |> validate_sign_up_for_interview(params)
    |> unique_constraint(:panelist_login_name, name: :interview_panelist_login_name_index, message: "You have already signed up for this interview")
    |> assoc_constraint(:interview, message: "Interview does not exist")
  end

  #TODO:'You have already signed up for the same interview' constraint error never occurs as it is handled here at changeset level itself
  defp validate_sign_up_for_interview(existing_changeset, %{"team_id" => team_id}) when team_id != nil, do: existing_changeset

  defp validate_sign_up_for_interview(existing_changeset, params) do
    interview_id = get_field(existing_changeset, :interview_id)
    panelist_login_name = get_field(existing_changeset, :panelist_login_name)
    panelist_experience = params["panelist_experience"]
    panelist_role = params["panelist_role"]
    if existing_changeset.valid? do
      interview = (Interview) |> Repo.get(interview_id)
      if !is_nil(interview) do
        retrieved_panelist_role = Role.retrieve_by_name(panelist_role)
        sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(panelist_login_name, Decimal.new(panelist_experience), retrieved_panelist_role)
        sign_up_evaluation_status = SignUpEvaluator.evaluate(sign_up_data_container, interview, Role.ba_and_pm_list)
        existing_changeset = existing_changeset |> update_changeset(sign_up_evaluation_status, sign_up_evaluation_status.valid?)
      end
    end
    existing_changeset
  end

  defp update_changeset(existing_changeset, sign_up_evaluation_status, true) do
    existing_changeset |> put_change(:satisfied_criteria, sign_up_evaluation_status.satisfied_criteria)
  end

  defp update_changeset(existing_changeset, sign_up_evaluation_status, false) do
    Enum.reduce(sign_up_evaluation_status.errors, existing_changeset, fn({field_name, description}, acc) ->
      add_error(acc, field_name, description)
    end)
  end

  def get_candidate_ids_interviewed_by(panelist_login_name) do
    (from ip in __MODULE__,
    where: ip.panelist_login_name == ^panelist_login_name,
    join: i in assoc(ip, :interview),
    select: i.candidate_id)
    |> Repo.all
  end

  def get_interviews_signed_up_by(panelist_login_name) do
    (from i in Interview,
      join: ip in assoc(i, :interview_panelist),
      where: ip.panelist_login_name == ^panelist_login_name,
      preload: [:interview_panelist, candidate: :candidate_skills])
  end

  def get_statistics(%{starting: starting, ending: ending}) do
    (from ip in __MODULE__,
      join: pd in PanelistDetails, on: ip.panelist_login_name == pd.panelist_login_name,
      join: r in assoc(pd, :role),
      join: i in Interview, on: i.start_time > ^starting and i.start_time < ^ending,
      right_join: t in assoc(ip, :team),
      group_by: [r.name, ip.panelist_login_name, t.name],
      where: t.active == true,
      select: [t.name, r.name, ip.panelist_login_name, count(ip.panelist_login_name)])
    end
end
