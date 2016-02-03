defmodule RecruitxBackend.CandidateSkillView do
  use RecruitxBackend.Web, :view

 def render("candidate_skill.json", %{candidate_skill: candidate_skill}) do
    %{
      id: candidate_skill.skill_id,
      candidate_id: candidate_skill.candidate_id
    }
  end

 def render("candidate_skill_id.json", %{candidate_skill: candidate_skill}) do
    %{
      skill_id: candidate_skill.skill_id
    }
  end
end
