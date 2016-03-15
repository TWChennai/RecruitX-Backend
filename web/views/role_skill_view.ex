defmodule RecruitxBackend.RoleSkillView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{role_skills: role_skills}) do
    %{data: render_many(role_skills, RecruitxBackend.RoleSkillView, "role_skill.json")}
  end

  def render("role_skill.json", %{role_skill: role_skill}) do
    %{role_id: role_skill.role_id,
      skill_id: role_skill.skill_id
    }
  end
end
