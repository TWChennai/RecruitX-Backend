defmodule RecruitxBackend.Repo.Migrations.CreateExperienceMatrix do
  use Ecto.Migration

  def change do
    create table(:experience_matrices) do
      add :panelist_experience_lower_bound, :integer, null: false
      add :candidate_experience_upper_bound, :integer, null: false
      add :interview_type_id, references(:interview_types, on_delete: :delete_all), null: false

      timestamps
    end

    create unique_index(:experience_matrices, [:panelist_experience_lower_bound,:candidate_experience_upper_bound,:interview_type_id], name: :experience_matrix_unique_index)
  end
end
