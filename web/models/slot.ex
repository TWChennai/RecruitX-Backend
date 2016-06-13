defmodule RecruitxBackend.Slot do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Timer
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.SlotCancellationNotification
  alias Timex.Date
  alias Ecto.Changeset

  @duration_of_interview 1

  schema "slots" do
    field :start_time, Timex.Ecto.DateTime
    field :end_time, Timex.Ecto.DateTime
    field :average_experience, :decimal
    field :skills, :string

    timestamps

    belongs_to :role, Role
    belongs_to :interview_type, InterviewType

    has_many :slot_panelists, SlotPanelist
  end

  @required_fields ~w(role_id interview_type_id start_time)
  @optional_fields ~w(end_time average_experience skills)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> populate_exp_skill_fields()
    |> has_interview_round_for_slot_creation(:skills)
    |> Timer.is_in_future(:start_time)
    |> Timer.is_less_than_a_month(:start_time)
    |> Timer.add_end_time(@duration_of_interview)
  end

  defp has_interview_round_for_slot_creation(existing_changeset, field) do
    if is_nil(existing_changeset.errors) or Enum.empty?(existing_changeset.errors) do
      skills = Changeset.get_field(existing_changeset, field)
      if is_nil(skills), do: existing_changeset = Changeset.add_error(existing_changeset, :slots, "No Interviews has been scheduled!")
    end
    existing_changeset
  end

  defp populate_exp_skill_fields(existing_changeset) do
    if is_nil(existing_changeset.errors) or Enum.empty?(existing_changeset.errors) do
      start_time = Changeset.get_field(existing_changeset, :start_time)
      interview_type_id = Changeset.get_field(existing_changeset, :interview_type_id)
      role_id = Changeset.get_field(existing_changeset, :role_id)
      candidates = Candidate.get_candidates_scheduled_for_date_and_interview_round(start_time, interview_type_id, role_id) |> Repo.all
      candidate_ids = Enum.map(candidates, &(&1.id))
      if !Enum.empty? candidates do
        existing_changeset = existing_changeset |> Changeset.put_change(:skills, Candidate.get_unique_skills_formatted(candidate_ids))
        existing_changeset = existing_changeset |> Changeset.put_change(:average_experience, calculate_average_experience (candidates))
      end
    end
    existing_changeset
  end

  defp calculate_average_experience(candidates) do
    sum_experience = Enum.reduce(candidates, Decimal.new(0), fn(candidate, acc) -> Decimal.add(acc, candidate.experience) end)
    Decimal.div(sum_experience , Decimal.new(Enum.count(candidates)))
  end

  def delete_unused_slots do
    current_time = Date.now |> Date.beginning_of_day
    past_slot_ids_query = (from s in __MODULE__,
    where: s.start_time < ^current_time)
    past_slot_ids_query |> SlotCancellationNotification.execute
    past_slot_ids_query |> Repo.delete_all
  end
end
