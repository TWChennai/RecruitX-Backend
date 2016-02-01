defmodule RecruitxBackend.Repo.Migrations.RenameCandidateInterviewScheduleTableToInterviews do
  use Ecto.Migration

  def change do
    rename table(:candidate_interview_schedules), to: table(:interviews)
    execute "ALTER SEQUENCE candidate_interview_schedules_id_seq RENAME TO interviews_id_seq"
    execute "ALTER TABLE interviews RENAME CONSTRAINT candidate_interview_schedules_pkey TO interviews_pkey";
    execute "ALTER TABLE interviews RENAME CONSTRAINT candidate_interview_schedules_candidate_id_fkey TO interviews_candidate_id_fkey";
    execute "ALTER TABLE interviews RENAME CONSTRAINT candidate_interview_schedules_interview_type_id_fkey TO interviews_interview_type_id_fkey";
    execute "ALTER INDEX candidate_interview_schedules_candidate_id_index RENAME TO interviews_candidate_id_index;"
    execute "ALTER INDEX candidate_interview_schedules_interview_id_index RENAME TO interviews_interview_type_id_index;"
    execute "ALTER INDEX candidate_interview_id_index RENAME TO candidate_interview_type_id_index;"
  end
end
