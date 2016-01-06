defmodule RecruitxBackend.Repo.Migrations.AddingLimitValidationForExperienceColumnInCandidates do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE candidates ADD CONSTRAINT positive_check CHECK((experience >= 0.0) AND (experience < 100));"
  end
end
