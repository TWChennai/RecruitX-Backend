defmodule RecruitxBackend.Repo.Migrations.CreateRoleSkill do
  use Ecto.Migration

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.RoleSkill
  alias RecruitxBackend.Skill

  def change do
    create table(:role_skills) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false

      timestamps
    end

    create unique_index(:role_skills, [:role_id, :skill_id], name: :role_skill_id_index)

    flush

    dev_role = Role.retrieve_by_name(Role.dev)
    Enum.each(["Java",
              "Ruby",
              "C#",
              "Python",
              "Other"], fn skill_value ->
      Repo.insert!(%RoleSkill{role_id: dev_role.id, skill_id: Skill.retrieve_by_name(skill_value).id})
    end)

    qa_role = Role.retrieve_by_name(Role.qa)
    Enum.each(["Selenium",
              "QTP",
              "Performance",
              "SOAPUI",
              "Other"], fn skill_value ->
      Repo.insert!(%RoleSkill{role_id: qa_role.id, skill_id: Skill.retrieve_by_name(skill_value).id})
    end)
  end
end
