defmodule RecruitxBackend.Interview do
  use RecruitxBackend.Web, :model

  @derive {Poison.Encoder, only: [:name, :priority]}
  schema "interviews" do
    field :name, :string
    field :priority, :integer

    timestamps

    has_many :candidate_interview_schedules, CandidateInterviewSchedule
  end

  @required_fields ~w(name priority)
  @optional_fields ~w()

  # TODO: Default sort order by priority

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z0-9]*$/i)
  end
end
