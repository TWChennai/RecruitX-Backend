defmodule RecruitxBackend.Timer do

  alias RecruitxBackend.TimexHelper
  alias Timex.Date
  alias Ecto.Changeset

  def get_previous_week do
    %{starting: Date.beginning_of_week(Date.now), ending: Date.end_of_week(Date.now) |> Date.shift(days: -2)}
  end

  def get_previous_month do
    day_from_previous_month = Date.now() |> Date.beginning_of_month |>  Date.shift(days: -1)
    %{starting: Date.beginning_of_month(day_from_previous_month), ending: Date.end_of_month(day_from_previous_month)}
  end

  def get_previous_quarter do
    day_from_previous_quarter = Date.now() |> Date.beginning_of_quarter |> Date.shift(days: -1)
    %{starting: Date.beginning_of_quarter(day_from_previous_quarter), ending: Date.end_of_quarter(day_from_previous_quarter)}
  end

  def add_end_time(existing_changeset, duration_of_interview) do
    incoming_start_time = existing_changeset |> Changeset.get_field(:start_time)
    if is_nil(existing_changeset.errors[:start_time]) and !is_nil(existing_changeset.changes[:start_time]) do
      min_valid_end_time = incoming_start_time |> Date.shift(hours: duration_of_interview)
      existing_changeset = existing_changeset |> Changeset.put_change(:end_time, min_valid_end_time)
    end
    existing_changeset
  end

  def is_in_future(existing_changeset, field) do
    if is_nil(existing_changeset.errors[:start_time]) and !is_nil(existing_changeset.changes[:start_time]) do
      new_start_time = Changeset.get_field(existing_changeset, field)
      current_time = (Date.now |> Date.shift(mins: -5))
      valid = TimexHelper.compare(new_start_time, current_time)
      if !valid, do: existing_changeset = Changeset.add_error(existing_changeset, field, "should be in the future")
    end
    existing_changeset
  end

  def is_less_than_a_month(existing_changeset, field) do
    if is_nil(existing_changeset.errors[:start_time]) and !is_nil(existing_changeset.changes[:start_time]) do
      new_start_time = Changeset.get_field(existing_changeset, field)
      current_time_after_a_month = Date.now |> Date.shift(months: 1)
      valid = TimexHelper.compare(current_time_after_a_month, new_start_time)
      if !valid, do: existing_changeset = Changeset.add_error(existing_changeset, field, "should be less than a month")
    end
    existing_changeset
  end

end
