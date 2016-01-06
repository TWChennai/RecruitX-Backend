defmodule RecruitxBackend.CandidateInterviewSchedule do
    use RecruitxBackend.Web, :model

    schema "candidate_interview_schedule" do
      belongs_to :candidate, Candidate
      belongs_to :interview, Interview
      field :interview_date, Ecto.Date
      field :interview_time, Ecto.Time

      timestamps
    end

    @required_fields ~w(candidate_id interview_id interview_date interview_time)
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
