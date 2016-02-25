defmodule RecruitxBackend.RoleView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.RoleView

  def render("index.json", %{roles: roles}) do
    render_many(roles, RoleView, "role.json")
  end

 def render("role.json", %{role: role}) do
    %{
      id: role.id,
      name: role.name
    }
  end
end
