defmodule RecruitxBackend.RoleSkill do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Role
  alias RecruitxBackend.Skill

  schema "role_skills" do
    belongs_to :role, Role
    belongs_to :skill, Skill
    timestamps()
  end

  @required_fields ~w(role_id skill_id)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> unique_constraint(:role_skill, name: :role_skill_id_index)
    |> assoc_constraint(:role)
    |> assoc_constraint(:skill)
  end
end
