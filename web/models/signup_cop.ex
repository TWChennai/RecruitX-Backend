defmodule RecruitxBackend.SignupCop do
  use RecruitxBackend.Web, :model

  schema "signup_cops" do
    field :name, :string

    timestamps()
  end

  def is_signup_cop(name) do
    (from sc in __MODULE__, where: sc.name == ^name) |> Repo.one |> is_not_nil
  end
end
