defmodule RecruitxBackend.Repo.Migrations.CreateSkill do
  use Ecto.Migration

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Skill

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
      Repo.insert!(%Skill{name: skill_value})
    end)
  end
end
