defmodule RecruitxBackend.Candidate do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Role
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Candidate

  schema "candidates" do
    field :name, :string
    field :experience, :decimal
    field :other_skills, :string

    timestamps

    belongs_to :role, Role
    belongs_to :pipeline_status, PipelineStatus
    has_many :candidate_skills, CandidateSkill
    has_many :interviews, Interview
    has_many :skills, through: [:candidate_skills, :skill]
  end

  @required_fields ~w(name experience role_id pipeline_status_id)
  @optional_fields ~w(other_skills)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z]*$/i)
    |> validate_number(:experience, greater_than_or_equal_to: Decimal.new(0),less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:role)
    |> assoc_constraint(:pipeline_status)
  end

  def get_candidates_in_fifo_order do
    from c in Candidate,
    join: i in assoc(c, :interviews),
    where: i.interview_type_id == 1,
    order_by: i.start_time,
    select: %{"id": c.id, "name": c.name, "experience": c.experience, "role_id": c.role_id}
  end
end
