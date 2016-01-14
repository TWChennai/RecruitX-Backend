defmodule RecruitxBackend.Repo.Migrations.CreateSkill do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX skills_name_index ON skills (UPPER(name));"
  end
end
