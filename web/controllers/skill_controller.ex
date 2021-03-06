defmodule RecruitxBackend.SkillController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Skill

  def index(conn, _params) do
    skills = Skill |> Repo.all
    conn |> render("index.json", skills: skills)
  end
end
