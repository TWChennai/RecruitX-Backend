defmodule RecruitxBackend.Repo.Migrations.AddingStatusColumnToInterviews do
  use Ecto.Migration

  def change do
    alter table(:interviews) do
      add :interview_status_id, references(:interview_status)

    end
  end
end
