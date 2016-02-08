defmodule RecruitxBackend.Repo.Migrations.CreateInterview do
  use Ecto.Migration

  def change do
    create table(:interviews) do
      add :start_time, :datetime, null: false
      add :candidate_id, references(:candidates), null: false
      add :interview_type_id, references(:interview_types), null: false

      timestamps
    end

    create unique_index(:interviews, [:candidate_id, :interview_type_id], name: :candidate_interview_type_id_index)
    create index(:interviews, [:candidate_id])
    create index(:interviews, [:interview_type_id])
  end
end