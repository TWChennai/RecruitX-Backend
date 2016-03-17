defmodule RecruitxBackend.RoleController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Role

  import Ecto.Query, only: [preload: 2]

  def index(conn, _params) do
    roles = Role
            |> preload(:role_skills)
            |> Repo.all
    conn |> render("index.json", roles: roles)
  end
end
