defmodule RecruitxBackend.Role do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Repo
  alias RecruitxBackend.RoleSkill
  alias RecruitxBackend.RoleInterviewType

  def dev, do: "Dev"
  def qa, do: "QA"
  def ba, do: "BA"
  def pm, do: "PM"
  def office_principal, do: "Off Prin"
  def other, do: "Other"

  schema "roles" do
    field :name, :string

    timestamps

    has_many :candidates, Candidate
    has_many :role_skills, RoleSkill
    has_many :role_interview_types, RoleInterviewType
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, AppConstants.name_format)
    |> unique_constraint(:name, name: :roles_name_index)
  end

  def retrieve_by_name(name), do: (from r in __MODULE__, where: r.name == ^name) |> Repo.one

  def is_ba_or_pm(role_id), do: role_id == retrieve_by_name(ba).id or role_id == retrieve_by_name(pm).id
  def ba_role_id, do: retrieve_by_name(ba).id
  def pm_role_id, do: retrieve_by_name(pm).id

  def get_all_roles, do: (from r in __MODULE__, where: r.name != ^other) |> Repo.all
end
