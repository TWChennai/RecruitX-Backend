defmodule RecruitxBackend.Candidate do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Role
  alias RecruitxBackend.Repo

  schema "candidates" do
    field :first_name, :string
    field :last_name, :string
    field :experience, :decimal
    field :other_skills, :string

    timestamps

    belongs_to :role, Role
    belongs_to :pipeline_status, PipelineStatus
    has_many :candidate_skills, CandidateSkill
    has_many :interviews, Interview
    has_many :skills, through: [:candidate_skills, :skill]
  end

  @required_fields ~w(first_name last_name experience role_id)
  @optional_fields ~w(other_skills pipeline_status_id)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> add_default_pipeline_status
    |> validate_length(:first_name, min: 1)
    |> validate_format(:first_name, AppConstants.name_format)
    |> validate_length(:last_name, min: 1)
    |> validate_format(:last_name, AppConstants.name_format)
    |> validate_number(:experience, greater_than_or_equal_to: Decimal.new(0),less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:role)
    |> assoc_constraint(:pipeline_status)
  end

  defp add_default_pipeline_status(existing_changeset) do
    incoming_id = existing_changeset |> get_field(:pipeline_status_id)
    if is_nil(incoming_id) do
      in_progess_id = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress).id
      existing_changeset = existing_changeset |> put_change(:pipeline_status_id, in_progess_id)
    end
    existing_changeset
  end

  def updateCandidateStatusAsPass(id) do
    candidate = __MODULE__ |> Repo.get(id)
    pass_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id
    candidate_params = %{
      "pipeline_status_id": pass_pipeline_status_id
    }
    change = __MODULE__.changeset(candidate, candidate_params)
    Repo.update(change)
  end

  def get_candidates_in_fifo_order do
    interview_type_id_with_min_priority = InterviewType.get_id_of_min_priority_round
    from c in __MODULE__,
      left_join: i in assoc(c, :interviews),
      where: i.interview_type_id == ^interview_type_id_with_min_priority or is_nil(i.interview_type_id),
      order_by: i.start_time,
      select: c
  end

  def is_pipeline_closed(candidate) do
    in_progress_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id
    candidate.pipeline_status_id == in_progress_id
  end

  def get_formatted_skills(candidate) do
    (Enum.reduce(candidate.skills, "", fn(skill, accumulator) ->
      skill_name = skill.name
      if skill_name == "Other", do: skill_name = candidate.other_skills
      accumulator <> ", " <> skill_name
    end))
    |> String.lstrip(?,)
    |> String.lstrip
  end

  def get_formatted_interviews(candidate) do
    Enum.map(candidate.interviews, &(Interview.format(&1)))
  end

end
