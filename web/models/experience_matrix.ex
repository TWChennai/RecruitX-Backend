defmodule RecruitxBackend.ExperienceMatrix do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role

  @roles_which_are_filtered [Role.dev, Role.qa]
  @max_experience Decimal.new(99)

  schema "experience_matrices" do
    field :panelist_experience_lower_bound, :decimal
    field :candidate_experience_lower_bound, :decimal
    field :candidate_experience_upper_bound, :decimal

    timestamps

    belongs_to :interview_type, InterviewType
    belongs_to :role, Role
  end

  @required_fields ~w(panelist_experience_lower_bound candidate_experience_lower_bound candidate_experience_upper_bound interview_type_id role_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_number(:candidate_experience_upper_bound, greater_than_or_equal_to: Decimal.new(0), less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> validate_number(:panelist_experience_lower_bound, greater_than_or_equal_to: Decimal.new(0), less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:interview_type)
    |> assoc_constraint(:role)
    |> unique_constraint(:experience_matrix_unique, name: :experience_matrix_unique_index, message: "This criteria is already specified")
  end

  def filter(_, nil), do: []

  def filter(panelist_experience, panelist_role) do
    (from e in __MODULE__,
    where: e.panelist_experience_lower_bound <= ^panelist_experience and e.role_id == ^(panelist_role.id),
    select: {e.candidate_experience_lower_bound, e.candidate_experience_upper_bound, e.interview_type_id})
    |> Repo.all
  end

  def get_max_experience_with_filter(role), do: get_max_experience_based_on_role(role, should_filter_role(role))

  defp get_max_experience_based_on_role(role, true),
  do: (from e in __MODULE__, where: e.role_id == ^role.id, select: max(e.panelist_experience_lower_bound)) |> Repo.one

  defp get_max_experience_based_on_role(_, false), do: @max_experience

  def get_interview_types_with_filter, do: (from e in __MODULE__, distinct: true, select: e.interview_type_id) |> Repo.all

  def should_filter_role(role), do: !is_nil(role) and Enum.member?(@roles_which_are_filtered, role.name)
end
