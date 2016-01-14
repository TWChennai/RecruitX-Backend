defmodule RecruitxBackend.RoleController do
    use RecruitxBackend.Web, :controller

    alias RecruitxBackend.Role

    def index(conn, _params) do
        json conn, Repo.all(Role)
    end
end
