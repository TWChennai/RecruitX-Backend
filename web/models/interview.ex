defmodule RecruitxBackend.Interview do
  use RecruitxBackend.Web, :model

  schema "interviews" do
    field :name, :string
    field :priority, :integer

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name)
    # TODO: check for case-insensitive contraint
  end
end
