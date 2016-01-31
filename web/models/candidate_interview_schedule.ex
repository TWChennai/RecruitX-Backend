defmodule RecruitxBackend.CandidateInterviewSchedule do
  use RecruitxBackend.Web, :model

  alias Ecto.DateTime
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.InterviewType

  @derive {Poison.Encoder, only: [:id, :candidate_interview_date_time, :candidate, :interview_type]}
  schema "candidate_interview_schedules" do
    field :candidate_interview_date_time, Ecto.DateTime
    belongs_to :candidate, Candidate
    belongs_to :interview_type, InterviewType

    timestamps
  end

  @required_fields ~w(candidate_id interview_type_id candidate_interview_date_time)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_date_time(:candidate_interview_date_time)
    |> unique_constraint(:interview_type_id, name: :candidate_interview_id_index)
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:interview_type)
  end

  def validate_date_time(existing_changeset, field) do
    value = get_field(existing_changeset, field)
    cast_date_time = DateTime.cast(value)
    if cast_date_time == :error && value != "", do: add_error(existing_changeset, :"#{field}", "is invalid"), else: existing_changeset
    existing_changeset
  end
end
