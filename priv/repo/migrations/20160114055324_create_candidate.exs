defmodule RecruitxBackend.Repo.Migrations.CreateCandidate do
  use Ecto.Migration

  def change do
    create table(:candidates) do
      add :name, :string
      add :experience, :decimal, null: false, precision: 4, scale: 2
      add :other_skills, :string
      add :role_id, references(:roles)

      timestamps
    end

    create index(:candidates, [:role_id])
  end
end
