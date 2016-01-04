defmodule RecruitxBackend.Repo.Migrations.CreateCandidateSkillTable do
  use Ecto.Migration

  def change do
    create table (:candidate_skills) do
      add :candidate_id, references(:candidates)
      add :skill_id, references(:skills)

      timestamps
    end
  end
end
