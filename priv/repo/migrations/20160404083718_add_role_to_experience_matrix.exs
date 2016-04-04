defmodule RecruitxBackend.Repo.Migrations.AddRoleToExperienceMatrix do
  use Ecto.Migration

  alias RecruitxBackend.Role

  def change do
    dev_role = Role.retrieve_by_name(Role.dev)
    alter table(:experience_matrices) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false, default: dev_role.id
    end

    create index(:experience_matrices, [:role_id])
    drop index(:experience_matrices, [:panelist_experience_lower_bound, :candidate_experience_lower_bound, :candidate_experience_upper_bound, :interview_type_id], name: :experience_matrix_unique_index)

    flush

    create unique_index(:experience_matrices, [:panelist_experience_lower_bound, :candidate_experience_lower_bound, :candidate_experience_upper_bound, :interview_type_id, :role_id], name: :experience_matrix_unique_index)
  end
end
