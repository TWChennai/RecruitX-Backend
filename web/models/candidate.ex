defmodule RecruitxBackend.Candidate do
    use RecruitxBackend.Web, :model

    alias RecruitxBackend.Role
    alias RecruitxBackend.CandidateSkill

    @derive {Poison.Encoder, only: [:name, :experience, :additional_information]}
    schema "candidates" do
        field :name, :string
        field :experience, :decimal
        field :additional_information, :string

        belongs_to :role, Role
        has_many :candidate_skills, CandidateSkill
        has_many :candidate_interview_schedule, CandidateInterviewSchedule
        timestamps
    end

    @required_fields ~w(name experience role_id)
    @optional_fields ~w(additional_information)

    def changeset(model, params \\ :empty) do
        model
            |> cast(params, @required_fields, @optional_fields)
            |> validate_length(:name, min: 1)
            |> validate_format(:name, ~r/^[a-z]+[\sa-z]*$/i)
            |> validate_number(:experience, greater_than_or_equal_to: Decimal.new(0),less_than: Decimal.new(100))
            |> foreign_key_constraint(:role_id)
    end
end
