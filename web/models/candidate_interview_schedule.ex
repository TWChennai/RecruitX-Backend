defmodule RecruitxBackend.CandidateInterviewSchedule do
  use RecruitxBackend.Web, :model

  @derive {Poison.Encoder, only: [:candidate_interview_date_time, :candidate_id, :interview_id]}
  schema "candidate_interview_schedules" do
    field :candidate_interview_date_time, Ecto.DateTime
    belongs_to :candidate, RecruitxBackend.Candidate
    belongs_to :interview, RecruitxBackend.Interview

    timestamps
  end

  @required_fields ~w(candidate_id interview_id candidate_interview_date_time)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
          |> unique_constraint(:candidate_interview_id_index, name: :candidate_interview_id_index)
          |> foreign_key_constraint(:candidate_id)
          |> foreign_key_constraint(:interview_id)
          # TODO: interview_date can't be nil
  end
end
