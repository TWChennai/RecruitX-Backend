defmodule RecruitxBackend.CandidateView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{candidates: candidates}) do
   render_many(candidates, RecruitxBackend.CandidateView, "candidates.json")
  end

  def render("show.json", %{candidate: candidate}) do
    render_one(candidate, RecruitxBackend.CandidateView, "candidate.json")
  end

  def render("candidate.json", %{candidate: candidate}) do
    %{
      id: candidate.id,
      name: candidate.name,
      role_id: candidate.role_id,
      other_skills: candidate.other_skills,
      experience: candidate.experience,
      skills: render_many(candidate.candidate_skills, RecruitxBackend.CandidateSkillView, "candidate_skill_id.json")
    }
  end

  def render("candidates.json", %{candidate: candidate}) do
    %{
      id: candidate.id,
      name: candidate.name,
      role_id: candidate.role_id,
      experience: candidate.experience
     }
  end
end
