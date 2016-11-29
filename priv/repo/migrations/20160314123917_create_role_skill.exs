defmodule RecruitxBackend.Repo.Migrations.CreateRoleSkill do
  use Ecto.Migration

  alias RecruitxBackend.Role
  alias RecruitxBackend.Skill

  def change do
    create table(:role_skills) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false

      timestamps
    end

    create index(:role_skills, [:role_id, :skill_id], unique: true, name: :role_skill_id_index)

    flush

    dev_role = Role.retrieve_by_name(Role.dev)
    Enum.each(["Java",
              "Ruby",
              "C#",
              "Python",
              "Other"], fn skill_value ->
      skill_id = Skill.retrieve_by_name(skill_value).id
      execute "INSERT INTO role_skills (role_id, skill_id, inserted_at, updated_at) VALUES (#{dev_role.id}, #{skill_id}, now(), now());"
    end)

    qa_role = Role.retrieve_by_name(Role.qa)
    Enum.each(["Selenium",
              "QTP",
              "Performance",
              "CI",
              "Other"], fn skill_value ->
      skill_id = Skill.retrieve_by_name(skill_value).id
      execute "INSERT INTO role_skills (role_id, skill_id, inserted_at, updated_at) VALUES (#{qa_role.id}, #{skill_id}, now(), now());"
    end)
  end
end
