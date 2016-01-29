defmodule RecruitxBackend.Repo.Migrations.AddUniqueIndexConstrainInCandidateSkill do
  use Ecto.Migration

  def change do
    create unique_index(:candidate_skills, [:candidate_id, :skill_id], name: :candidate_skill_id_index)
  end
end
