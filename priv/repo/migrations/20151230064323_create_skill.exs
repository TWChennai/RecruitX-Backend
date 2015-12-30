defmodule RecruitxBackend.Repo.Migrations.CreateSkill do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string, null: false

      timestamps
    end

  end
end
