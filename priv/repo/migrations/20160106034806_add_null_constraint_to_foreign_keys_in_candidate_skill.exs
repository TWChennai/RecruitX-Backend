defmodule RecruitxBackend.Repo.Migrations.AddNullConstraintToForeignKeysInCandidateSkill do
  use Ecto.Migration

  def change do
    alter table(:candidate_skills) do
        remove :candidate_id
        remove :skill_id

        add :candidate_id, references(:candidates), null: false
        add :skill_id, references(:skills), null: false
    end
  end
end
