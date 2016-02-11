defmodule RecruitxBackend.FeedbackImage do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview

  schema "feedback_images" do
    field :file_name, :string

    belongs_to :interview, Interview

    timestamps
  end

  @required_fields ~w(file_name interview_id)
  @optional_fields ~w()

  def changeset(model, params) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:file_name, min: 1)
    |> validate_format(:file_name, ~r/^[a-z]+[\sa-z0-9_.]*$/i)
    |> assoc_constraint(:interview)
  end
end
