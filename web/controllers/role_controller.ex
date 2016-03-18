defmodule RecruitxBackend.RoleController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Role

  def index(conn, _params) do
    roles = Role
            |> preload(:role_skills)
            |> Repo.all
    conn |> render("index.json", roles: roles)
  end
end
