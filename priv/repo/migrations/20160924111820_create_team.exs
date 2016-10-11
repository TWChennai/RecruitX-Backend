defmodule RecruitxBackend.Repo.Migrations.CreateTeam do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX team_name_index ON teams (UPPER(name));"
  end
end
