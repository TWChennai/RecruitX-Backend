defmodule RecruitxBackend.Repo.Migrations.RenameInterviewTypesPkeyIndex do
  use Ecto.Migration

  def change do
    execute "ALTER SEQUENCE interviews_id_seq RENAME TO interview_types_id_seq"
    execute "ALTER TABLE interview_types RENAME CONSTRAINT interviews_pkey TO interview_types_pkey";
  end
end
