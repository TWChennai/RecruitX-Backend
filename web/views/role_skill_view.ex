defmodule RecruitxBackend.RoleSkillView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{role_skills: role_skills}) do
    render_many(role_skills, __MODULE__, "role_skill.json")
  end

  def render("role_skill.json", %{role_skill: role_skill}) do
    %{
      id: role_skill.skill_id
    }
  end
end
