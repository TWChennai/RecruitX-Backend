defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Panelist

  @derive {Poison.Encoder, only: [:id, :panelist_login_name]}
  schema "interview_panelists" do
    field :panelist_login_name, :string

    belongs_to :interview, Interview

    timestamps
  end

  @required_fields ~w(panelist_login_name interview_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_format(:panelist_login_name, ~r/^[a-z]+[\sa-z]*$/i)
    |> unique_constraint(:panelist_login_name, name: :interview_panelist_login_name_index)
    |> assoc_constraint(:interview)
  end
end
