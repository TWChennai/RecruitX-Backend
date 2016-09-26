defmodule RecruitxBackend.Repo.Migrations.AddActiveFieldToTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :active, :boolean ,default: true, null: false
    end
  end
end
