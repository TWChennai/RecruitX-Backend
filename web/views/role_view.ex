defmodule RecruitxBackend.RoleView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.RoleView
  alias RecruitxBackend.RoleSkillView

  def render("index.json", %{roles: roles}) do
    render_many(roles, RoleView, "role.json")
  end

 def render("role_without_skills.json", %{role: role}) do
    %{
      id: role.id,
      name: role.name
    }
 end

 def render("role.json", %{role: role}) do
    %{
      id: role.id,
      name: role.name,
      skills: render_many(role.role_skills, RoleSkillView, "role_skill.json")
    }
  end
end
