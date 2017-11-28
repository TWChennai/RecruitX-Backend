defmodule RecruitxBackend.SignUpView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{sign_up: signups}) do
    group_by_role = signups |> Enum.group_by(&Enum.at(&1, 1))
    render_many(group_by_role, __MODULE__, "sign_up_group_by_role.json")
  end

  def render("sign_up_group_by_role.json", %{sign_up: {role, signup}}) do
    %{
      names: signup |> Enum.map(&(Enum.at(&1, 2))),
      role: role,
      count: signup |> Enum.map(&Enum.at(&1, 3)) |> Enum.reduce(0, &(&1 + &2))
     }
    end
end
