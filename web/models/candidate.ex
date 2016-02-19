defmodule RecruitxBackend.Candidate do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Role
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Candidate

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
    |> validate_format(:first_name, ~r/^[a-z]+[\sa-z]*$/i)
    |> validate_length(:last_name, min: 1)
    |> validate_format(:last_name, ~r/^[a-z]+[\sa-z]*$/i)
    |> validate_number(:experience, greater_than_or_equal_to: Decimal.new(0),less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:role)
    |> assoc_constraint(:pipeline_status)
  end

  defp add_default_pipeline_status(existing_changeset) do
    incoming_id = existing_changeset |> get_field(:pipeline_status_id)
    if is_nil(incoming_id) do
      in_progess_id = PipelineStatus.retrieve_by_name("In Progress").id
      existing_changeset = existing_changeset |> put_change(:pipeline_status_id, in_progess_id)
    end
    existing_changeset
  end

  def get_candidates_in_fifo_order do
    from c in Candidate,
    join: i in assoc(c, :interviews),
    where: i.interview_type_id == 1,    # TODO: Is this correct?
    order_by: i.start_time,
    select: c
  end
end
