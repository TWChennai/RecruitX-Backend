defmodule RecruitxBackend.Repo.Migrations.CreateTempTableToUpdateTeamDetails do
  use Ecto.Migration

  def change do
    create table(:update_team_details) do
      add :panelist_login_name, :string, null: false
      add :interview_panelist_id, references(:interview_panelists, on_delete: :delete_all), null: false
      add :processed, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:update_team_details, [:panelist_login_name, :interview_panelist_id], name: :interview_panelist_login_id_index)
  end
end
