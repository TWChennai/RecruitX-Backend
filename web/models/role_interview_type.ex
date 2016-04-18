defmodule RecruitxBackend.RoleInterviewType do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewType

  schema "role_interview_types" do
    field :optional, :boolean, default: false
    belongs_to :role, Role
    belongs_to :interview_type, InterviewType

    timestamps
  end

  @required_fields ~w(role_id interview_type_id)
  @optional_fields ~w(optional)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:role_interview_type, name: :role_interview_type_id_index)
    |> assoc_constraint(:role)
    |> assoc_constraint(:interview_type)
  end
end
