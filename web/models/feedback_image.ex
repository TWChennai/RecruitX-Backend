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
    |> validate_format(:file_name, ~r/^[a-z]+[\sa-z0-9_.-]*$/i)
    |> unique_constraint(:file_name_unique, name: :feedback_file_name_interview_id_unique_index, message: "This file has already been uploaded")
    |> unique_constraint(:file_name, name: :file_name_unique_index)
    |> assoc_constraint(:interview, message: "Interview has been deleted")
  end

  def get_full_path(feedback_image) do
    "https://" <> System.get_env("AWS_DOWNLOAD_URL") <> feedback_image.file_name
  end
end
