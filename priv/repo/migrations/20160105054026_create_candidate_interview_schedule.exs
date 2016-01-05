defmodule RecruitxBackend.Repo.Migrations.CreateCandidateInterviewSchedule do
  use Ecto.Migration

  def change do
    create table(:candidate_interview_schedule) do
      add :candidate_id, references(:candidates), null: false
      add :interview_id, references(:interviews), null: false
      add :interview_date, :date, null: false
      add :interview_time, :time, null: false

      timestamps
    end
    create unique_index(:candidate_interview_schedule, [:candidate_id, :interview_id], name: :candidate_interview_id_index)
  end
end
