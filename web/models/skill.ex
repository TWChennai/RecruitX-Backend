defmodule RecruitxBackend.Skill do
  use RecruitxBackend.Web, :model

  schema "skills" do
    field :name, :string

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name)
    |> validate_length(:name, min: 1, max: 255)
  end
end
