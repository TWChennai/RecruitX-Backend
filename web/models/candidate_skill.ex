defmodule RecruitxBackend.CandidateSkill do
  use RecruitxBackend.Web, :model

  schema "candidate_skills" do
    belongs_to :candidate, RecruitxBackend.Candidate
    belongs_to :skill, RecruitxBackend.Skill

    timestamps
  end

  @required_fields ~w(candidate_id skill_id)
  @optional_fields ~w()

  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:candidate_id)
    |> foreign_key_constraint(:skill_id)
  end
end
