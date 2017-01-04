defmodule RecruitxBackend.CandidateSkill do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Skill

  schema "candidate_skills" do
    belongs_to :candidate, Candidate
    belongs_to :skill, Skill

    timestamps()
  end

  @required_fields ~w(candidate_id skill_id)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> unique_constraint(:skill_id, name: :candidate_skill_id_index)
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:skill)
  end
end
