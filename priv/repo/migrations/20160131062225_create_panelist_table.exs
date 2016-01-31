defmodule RecruitxBackend.Repo.Migrations.CreatePanelistTable do
  use Ecto.Migration

  def change do
    create table(:panelists) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX panelist_name_index ON panelists (UPPER(name));"
  end
end
