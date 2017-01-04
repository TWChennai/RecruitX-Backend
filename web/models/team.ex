defmodule RecruitxBackend.Team do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Repo

  schema "teams" do
    field :name, :string
    field :active, :boolean, default: true

    timestamps()
  end

  @required_fields ~w(name)
  @optional_fields ~w(active)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> unique_constraint(:name, name: :team_name_index)
  end

  def retrieve_by_name(name), do: (from r in __MODULE__, where: r.name == ^name) |> Repo.one
end
