defmodule RecruitxBackend.SkillView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{skills: skills}) do
   render_many(skills, RecruitxBackend.SkillView, "skill.json")
  end

  def render("skill.json", %{skill: skill}) do
    %{
      id: skill.id,
      name: skill.name
    }
  end
end
