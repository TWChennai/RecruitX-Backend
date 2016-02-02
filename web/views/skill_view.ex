defmodule RecruitxBackend.SkillView do
  use RecruitxBackend.Web, :view

 def render("skill.json", %{skill: skill}) do
    %{
      id: skill.id,
      name: skill.name
    }
  end

 def render("skill_without_id.json", %{skill: skill}) do
    %{
      name: skill.name
    }
  end
end
