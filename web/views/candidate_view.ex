defmodule RecruitxBackend.CandidateView do
  use RecruitxBackend.Web, :view

 def render("candidate.json", %{candidate: candidate}) do
    %{
      id: candidate.id,
      name: candidate.name,
      role_id: candidate.role_id,
      other_skills: candidate.other_skills,
      skills: render_many(candidate.skills, RecruitxBackend.SkillView, "skill_without_id.json")
    }
  end
end
