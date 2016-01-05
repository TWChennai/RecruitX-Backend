defmodule RecruitxBackend.Skill do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Skill

  schema "skills" do
    field :name, :string

    timestamps

    has_many :candidate_skills, CandidateSkill
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z]*$/i)
  end
end
