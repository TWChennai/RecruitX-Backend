defmodule RecruitxBackend.Repo.Migrations.RenameTableInterviewToInterviewType do
  use Ecto.Migration

  def change do
    rename table(:interviews), to: table(:interview_types)

    rename table(:candidate_interview_schedules), :interview_id, to: :interview_type_id

    execute "ALTER INDEX interviews_name_index RENAME TO interview_types_name_index;"
    execute "ALTER TABLE candidate_interview_schedules RENAME CONSTRAINT candidate_interview_schedules_interview_id_fkey TO candidate_interview_schedules_interview_type_id_fkey";
  end
end
