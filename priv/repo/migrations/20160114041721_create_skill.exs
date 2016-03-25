defmodule RecruitxBackend.Repo.Migrations.CreateSkill do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX skills_name_index ON skills (UPPER(name));"

    flush

    Enum.each(["Java",
              "Ruby",
              "C#",
              "Python",
              "Other"], fn skill_value ->
      execute "INSERT INTO skills (name, inserted_at, updated_at) VALUES ('#{skill_value}', now(), now());"
    end)
  end
end
