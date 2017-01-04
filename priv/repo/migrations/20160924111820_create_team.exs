defmodule RecruitxBackend.Repo.Migrations.CreateTeam do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false

      timestamps()
    end

    create index(:teams, ["UPPER(name)"], unique: true, name: :team_name_index)
  end
end
