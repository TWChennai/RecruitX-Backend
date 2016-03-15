defmodule RecruitxBackend.ExperienceMatrix do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.InterviewType

  schema "experience_matrices" do
    field :panelist_experience_lower_bound, :integer
    field :candidate_experience_upper_bound, :integer

    timestamps

    belongs_to :interview_type, InterviewType
  end

  @required_fields ~w(panelist_experience_lower_bound candidate_experience_upper_bound interview_type_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_number(:candidate_experience_upper_bound, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, message: "must be in the range 0-100")
    |> validate_number(:panelist_experience_lower_bound, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, message: "must be in the range 0-100")
    |> assoc_constraint(:interview_type)
    |> unique_constraint(:experience_matrix_unique, name: :experience_matrix_unique_index, message: "This criteria is already specified")
  end
end
