defmodule RecruitxBackend.Team do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Repo

  schema "teams" do
    field :name, :string

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name, name: :team_name_index)
  end

  def retrieve_by_name(name), do: (from r in __MODULE__, where: r.name == ^name) |> Repo.one
end
