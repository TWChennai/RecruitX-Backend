defmodule RecruitxBackend.Panelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.InterviewPanelist

  @derive {Poison.Encoder, only: [:id, :name]}
  schema "panelists" do
    field :name, :string

    timestamps

    has_many :interview_panelist, InterviewPanelist
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z]*$/i)
    |> unique_constraint(:name)
  end
end
