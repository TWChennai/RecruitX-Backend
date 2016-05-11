defmodule RecruitxBackend.Slot do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Timer

  @duration_of_interview 1

  schema "slots" do
    field :start_time, Timex.Ecto.DateTime
    field :end_time, Timex.Ecto.DateTime

    timestamps

    belongs_to :role, Role
    belongs_to :interview_type, InterviewType
  end

  @required_fields ~w(role_id interview_type_id start_time)
  @optional_fields ~w(end_time)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> Timer.is_in_future(:start_time)
    |> Timer.should_less_than_a_month(:start_time)
    |> Timer.add_end_time(@duration_of_interview)
  end

end
