defmodule RecruitxBackend.Repo.Migrations.AlterExperienceMatrixColumnTypes do
  use Ecto.Migration

  def change do
    alter table(:experience_matrices) do
      modify :panelist_experience_lower_bound, :decimal, null: false, precision: 4, scale: 1
      modify :candidate_experience_upper_bound, :decimal, null: false, precision: 4, scale: 1
    end
  end
end
