defmodule RecruitxBackend.SkillController do
    use RecruitxBackend.Web, :controller

    alias RecruitxBackend.Skill

    def index(conn, _params) do
        json conn, Repo.all(Skill)
    end
end
