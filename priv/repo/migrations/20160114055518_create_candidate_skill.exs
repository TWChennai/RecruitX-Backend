defmodule RecruitxBackend.Repo.Migrations.CreateCandidateSkill do
  use Ecto.Migration

  def change do
    create table(:candidate_skills) do
      add :candidate_id, references(:candidates), null: false
      add :skill_id, references(:skills), null: false

      timestamps
    end

    create unique_index(:candidate_skills, [:candidate_id, :skill_id], name: :candidate_skill_id_index)
    create index(:candidate_skills, [:candidate_id])
    create index(:candidate_skills, [:skill_id])
  end
end
