defmodule RecruitxBackend.CandidateInterviewSchedule do
  use RecruitxBackend.Web, :model

  alias Ecto.DateTime
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview

  @derive {Poison.Encoder, only: [:candidate_interview_date_time, :candidate, :interview]}
  schema "candidate_interview_schedules" do
    field :candidate_interview_date_time, Ecto.DateTime
    belongs_to :candidate, Candidate
    belongs_to :interview, Interview

    timestamps
  end

  @required_fields ~w(candidate_id interview_id candidate_interview_date_time)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_date_time(:candidate_interview_date_time)
    |> unique_constraint(:candidate_interview_id_index, name: :candidate_interview_id_index)
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:interview)
  end

  def validate_date_time(existing_changeset, field) do
    value = get_field(existing_changeset, field)
    cast_date_time = DateTime.cast(value)
    if cast_date_time == :error && value != "", do: add_error(existing_changeset, :"#{field}", "is invalid"), else: existing_changeset
    existing_changeset
  end
end
