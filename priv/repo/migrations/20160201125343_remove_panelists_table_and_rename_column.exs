defmodule RecruitxBackend.Repo.Migrations.RemovePanelistsTableAndRenameColumn do
  use Ecto.Migration

  def change do
    drop table(:interview_panelist)
    drop table(:panelists)

    create table(:interview_panelists) do
      add :panelist_login_name, :string, null: false
      add :interview_id, references(:interviews), null: false

      timestamps
    end

    create unique_index(:interview_panelists, [:panelist_login_name, :interview_id], name: :interview_panelist_login_name_index)
    create index(:interview_panelists, [:panelist_login_name])
    create index(:interview_panelists, [:interview_id])
    execute "CREATE UNIQUE INDEX panelist_login_name_index ON interview_panelists (UPPER(panelist_login_name));"
  end
end
