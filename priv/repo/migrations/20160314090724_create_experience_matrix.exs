defmodule RecruitxBackend.Repo.Migrations.CreateExperienceMatrix do
  use Ecto.Migration

  def change do
    create table(:experience_matrices) do
      add :panelist_experience_lower_bound, :decimal, null: false, precision: 4, scale: 2
      add :candidate_experience_lower_bound, :decimal, null: false, precision: 4, scale: 2
      add :candidate_experience_upper_bound, :decimal, null: false, precision: 4, scale: 2
      add :interview_type_id, references(:interview_types, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:experience_matrices, [:panelist_experience_lower_bound, :candidate_experience_lower_bound, :candidate_experience_upper_bound, :interview_type_id], unique: true, name: :experience_matrix_unique_index)
  end
end
