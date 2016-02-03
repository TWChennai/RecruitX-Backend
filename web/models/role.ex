defmodule RecruitxBackend.Role do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Candidate

  schema "roles" do
    field :name, :string

    timestamps

    has_many :candidates, Candidate
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z]*$/i)
    |> unique_constraint(:name)
  end
end
