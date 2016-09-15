defmodule RecruitxBackend.CandidateView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.CandidateSkillView
  alias RecruitxBackend.CandidateView
  alias RecruitxBackend.RoleView
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Candidate

  def render("index.json", %{candidates: candidates}) do
    %{
      total_pages: candidates.total_pages,
      candidates: render_many(candidates.entries, CandidateView, "candidate.json")
    }
  end

  def render("show.json", %{candidate: candidate}) do
    render_one(candidate, CandidateView, "candidate_with_skills.json")
  end

  def render("update.json", %{candidate: candidate}) do
    render_one(candidate, CandidateView, "candidate.json")
  end

  def render("candidate_with_skills.json", %{candidate: candidate}) do
    %{
      id: candidate.id,
      first_name: candidate.first_name,
      last_name: candidate.last_name,
      role_id: candidate.role_id,
      other_skills: candidate.other_skills,
      experience: candidate.experience,
      pipeline_status_id: candidate.pipeline_status_id,
      skills: render_many(candidate.candidate_skills, CandidateSkillView, "candidate_skill_id.json")
    }
  end

  def render("candidate_with_skills_preload.json", %{candidate: candidate}) do
    %{
      id: candidate.id,
      first_name: candidate.first_name,
      last_name: candidate.last_name,
      role: render_one(candidate.role, RoleView, "role_without_skills.json"),
      other_skills: candidate.other_skills,
      experience: candidate.experience,
      pipeline_status_id: candidate.pipeline_status_id,
      skills: Candidate.get_formatted_skills(candidate)
    }
  end

  def render("dummy_candidate.json", %{candidate: %{role_id: role_id, skills: skills, average_experience: experience}}) do
    %{
      id: nil,
      first_name: "???",
      last_name: "",
      role_id: role_id,
      other_skills: skills,
      experience: experience,
      pipeline_status_id: PipelineStatus.retrieve_by_name(PipelineStatus.in_progress).id,
      skills: ""
    }
  end

  def render("dummy_candidate_preload.json", %{candidate: %{skills: skills, average_experience: experience, role: role}}) do
    %{
      id: nil,
      first_name: "???",
      last_name: "",
      role: render_one(role, RoleView, "role_without_skills.json"),
      other_skills: skills,
      experience: experience,
      pipeline_status_id: PipelineStatus.retrieve_by_name(PipelineStatus.in_progress).id,
      skills: ""
    }
  end

  def render("candidate.json", %{candidate: candidate}) do
    %{
      id: candidate.id,
      first_name: candidate.first_name,
      last_name: candidate.last_name,
      role_id: candidate.role_id,
      experience: candidate.experience,
      pipeline_status_id: candidate.pipeline_status_id
    }
  end
end
