defmodule RecruitxBackend.Repo.Migrations.CreateWeekendDrive do
  use Ecto.Migration

  def change do
    create table(:weekend_drives) do
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :no_of_candidates, :integer, null: false
      add :no_of_panelists, :integer
      add :role_id, references(:roles)

      timestamps
    end
    create index(:weekend_drives, [:role_id])

  end
end
