defmodule RecruitxBackend.Repo.Migrations.CreateInterviewPanelistTable do
  use Ecto.Migration

  def change do
    create table(:interview_panelist) do
      add :panelist_id, references(:panelists), null: false
      add :interview_id, references(:candidate_interview_schedules), null: false

      timestamps
    end

    create unique_index(:interview_panelist, [:panelist_id, :interview_id], name: :interview_panelist_id_index)
    create index(:interview_panelist, [:panelist_id])
    create index(:interview_panelist, [:interview_id])
  end
end
