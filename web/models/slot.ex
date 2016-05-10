defmodule RecruitxBackend.Slot do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewType
  alias Timex.Date

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
    |> calculate_end_time
  end

  defp calculate_end_time(existing_changeset) do
    incoming_start_time = existing_changeset |> get_field(:start_time)
    if is_nil(existing_changeset.errors[:start_time]) and !is_nil(existing_changeset.changes[:start_time]) do
      min_valid_end_time = incoming_start_time |> Date.shift(hours: @duration_of_interview)
      existing_changeset = existing_changeset |> put_change(:end_time, min_valid_end_time)
    end
    existing_changeset
  end
end
