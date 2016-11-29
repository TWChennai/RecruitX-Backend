defmodule RecruitxBackend.Repo.Migrations.CreateInterview do
  use Ecto.Migration

  def change do
    create table(:interviews) do
      add :start_time, :datetime, null: false
      add :end_time, :datetime, null: false
      add :candidate_id, references(:candidates, on_delete: :delete_all), null: false
      add :interview_type_id, references(:interview_types), null: false
      add :interview_status_id, references(:interview_status)

      timestamps
    end

    create index(:interviews, [:candidate_id, :interview_type_id], unique: true, name: :candidate_interview_type_id_index)
    create index(:interviews, [:candidate_id])
    create index(:interviews, [:interview_type_id])
  end
end
