defmodule RecruitxBackend.InterviewStatus do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.Interview

  def pass, do: "Pass"
  def pursue, do: "Pursue"
  def strong_pursue, do: "Strong Pursue"

  schema "interview_status" do
    field :name, :string

    has_many :interviews, Interview

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, AppConstants.name_format)
    |> unique_constraint(:name, name: :interview_status_name_index)
  end
end
