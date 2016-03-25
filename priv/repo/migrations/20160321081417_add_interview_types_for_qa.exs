defmodule RecruitxBackend.Repo.Migrations.AddInterviewTypesForQa do
  use Ecto.Migration

  def change do
    execute "INSERT INTO interview_types (name, priority, inserted_at, updated_at) VALUES ('TP', 1, now(), now());"
  end
end
