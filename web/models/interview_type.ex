defmodule RecruitxBackend.InterviewType do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview

  schema "interview_types" do
    field :name, :string
    field :priority, :integer

    timestamps

    has_many :interviews, Interview
  end

  @required_fields ~w(name)
  @optional_fields ~w(priority)

  def default_order(query) do
    from i in query, order_by: [asc: i.priority, asc: i.id]
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z0-9]*$/i)
    |> unique_constraint(:name)
  end
end
