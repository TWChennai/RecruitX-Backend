defmodule RecruitxBackend.Skill do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.RoleSkill
  alias RecruitxBackend.Repo

  schema "skills" do
    field :name, :string

    timestamps()

    has_many :candidate_skills, CandidateSkill
    has_many :role_skills, RoleSkill
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, AppConstants.name_format)
    |> unique_constraint(:name, name: :skills_name_index)
  end

  def retrieve_by_name(name), do: (from s in __MODULE__, where: s.name == ^name) |> Repo.one

  def other_skill do
    retrieve_by_name("Other")
  end
end
