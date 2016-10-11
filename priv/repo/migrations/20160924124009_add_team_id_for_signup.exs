defmodule RecruitxBackend.Repo.Migrations.AddTeamIdForSignup do
  use Ecto.Migration

  def change do
    alter table(:interview_panelists) do
      add :team_id, references(:teams), null: true
    end
  end
end
