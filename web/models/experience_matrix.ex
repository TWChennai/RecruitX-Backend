defmodule RecruitxBackend.ExperienceMatrix do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo
  alias RecruitxBackend.ExperienceMatrix

  schema "experience_matrices" do
    field :panelist_experience_lower_bound, :decimal
    field :candidate_experience_upper_bound, :decimal

    timestamps

    belongs_to :interview_type, InterviewType
  end

  @required_fields ~w(panelist_experience_lower_bound candidate_experience_upper_bound interview_type_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_number(:candidate_experience_upper_bound, greater_than_or_equal_to: Decimal.new(0), less_than_or_equal_to: Decimal.new(100), message: "must be in the range 0-100")
    |> validate_number(:panelist_experience_lower_bound, greater_than_or_equal_to: Decimal.new(0), less_than_or_equal_to: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:interview_type)
    |> unique_constraint(:experience_matrix_unique, name: :experience_matrix_unique_index, message: "This criteria is already specified")
  end

  def is_eligible(panelist_experience, candidate_experience, interview_type_id) do
    max_experience_with_filter = (from e in ExperienceMatrix, select: max(e.panelist_experience_lower_bound)) |> Repo.one
    interview_types_with_filter = (from e in ExperienceMatrix, distinct: true, select: e.interview_type_id) |> Repo.all

    to_float(panelist_experience) > to_float(max_experience_with_filter)
    or !Enum.member?(interview_types_with_filter, interview_type_id)
    or panelist_experience |> is_eligible_based_on_filter(candidate_experience,interview_type_id)
  end

  defp is_eligible_based_on_filter(panelist_experience,candidate_experience,interview_type_id) do
    eligible_criteria = filter(panelist_experience) |> Repo.all
    Enum.any?(eligible_criteria, fn({eligible_candidate_experience, eligible_interview_type_id}) ->
      interview_type_id == eligible_interview_type_id and to_float(candidate_experience) <= to_float(eligible_candidate_experience)
    end)
  end

  def filter(panelist_experience) do
    from e in __MODULE__,
    where: e.panelist_experience_lower_bound <= ^panelist_experience,
    select: {e.candidate_experience_upper_bound, e.interview_type_id}
  end

  defp to_float(input), do: Float.parse(input |> Decimal.to_string())
end

