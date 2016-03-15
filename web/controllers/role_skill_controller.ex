defmodule RecruitxBackend.RoleSkillController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.RoleSkill

  def index(conn, _params) do
    role_skills = Repo.all(RoleSkill)
    render(conn, "index.json", role_skills: role_skills)
  end
end
