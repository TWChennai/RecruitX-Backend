defmodule RecruitxBackend.Interview do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview

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
  end

  def getByName(interview_name) do
    from i in Interview, where: i.name == ^interview_name
  end
end
