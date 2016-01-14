defmodule RecruitxBackend.Repo.Migrations.CreateCandidateInterviewSchedule do
  use Ecto.Migration

  def change do
    create table(:candidate_interview_schedules) do
      add :candidate_interview_date_time, :datetime, null: false
      add :candidate_id, references(:candidates), null: false
      add :interview_id, references(:interviews), null: false

      timestamps
    end

    create unique_index(:candidate_interview_schedules, [:candidate_id, :interview_id], name: :candidate_interview_id_index)
    create index(:candidate_interview_schedules, [:candidate_id])
    create index(:candidate_interview_schedules, [:interview_id])
  end
end
