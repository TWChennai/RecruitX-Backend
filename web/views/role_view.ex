defmodule RecruitxBackend.RoleView do
  use RecruitxBackend.Web, :view

 def render("index.json", %{roles: roles}) do
    render_many(roles, RecruitxBackend.RoleView, "role.json")
  end

 def render("role.json", %{role: role}) do
    %{
      id: role.id,
      name: role.name
    }
  end
end
