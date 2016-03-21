defmodule RecruitxBackend.ExperienceMatrix do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo

  schema "experience_matrices" do
    field :panelist_experience_lower_bound, :decimal
    field :candidate_experience_lower_bound, :decimal
    field :candidate_experience_upper_bound, :decimal

    timestamps

    belongs_to :interview_type, InterviewType
  end

  @required_fields ~w(panelist_experience_lower_bound candidate_experience_lower_bound candidate_experience_upper_bound interview_type_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_number(:candidate_experience_upper_bound, greater_than_or_equal_to: Decimal.new(0), less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> validate_number(:panelist_experience_lower_bound, greater_than_or_equal_to: Decimal.new(0), less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:interview_type)
    |> unique_constraint(:experience_matrix_unique, name: :experience_matrix_unique_index, message: "This criteria is already specified")
  end

  def filter(panelist_experience) do
    from e in __MODULE__,
    where: e.panelist_experience_lower_bound <= ^panelist_experience,
    select: {e.candidate_experience_lower_bound, e.candidate_experience_upper_bound, e.interview_type_id}
  end

  def get_max_experience_with_filter, do: (from e in __MODULE__, select: max(e.panelist_experience_lower_bound)) |> Repo.one

  def get_interview_types_with_filter, do: (from e in __MODULE__, distinct: true, select: e.interview_type_id) |> Repo.all
end
