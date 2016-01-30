defmodule RecruitxBackend.Candidate do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.CandidateInterviewSchedule
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Role

  @derive {Poison.Encoder, only: [:name, :experience, :additional_information, :role]}
  schema "candidates" do
    field :name, :string
    field :experience, :decimal
    field :additional_information, :string
    belongs_to :role, Role

    timestamps

    has_many :candidate_skills, CandidateSkill
    has_many :candidate_interview_schedules, CandidateInterviewSchedule
  end

  @required_fields ~w(name experience role_id)
  @optional_fields ~w(additional_information)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z]*$/i)
    |> validate_number(:experience, greater_than_or_equal_to: Decimal.new(0),less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:role)
  end

  # TODO: Just an example - still incomplete.
  def with_name(query, name) do
    from c in query, where: ilike(c.name, ^"%#{name}%")
  end
end
