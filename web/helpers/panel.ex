defmodule RecruitxBackend.Panel do

  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo
  alias Timex.Date
  alias Ecto.Changeset
  import Ecto.Query

  def validate_panelist_experience(%{valid?: true} = existing_changeset, nil), do: Changeset.add_error(existing_changeset, :panelist_experience, "can't be blank")

  def validate_panelist_experience(existing_changeset, _), do: existing_changeset

  def validate_panelist_role(%{valid?: true} = existing_changeset, nil), do: Changeset.add_error(existing_changeset, :panelist_role, "can't be blank")

  def validate_panelist_role(existing_changeset, _), do: existing_changeset

  def get_start_times_interviewed_by(panelist_login_name) do
    ((from ip in InterviewPanelist,
      where: ip.panelist_login_name == ^panelist_login_name,
      join: i in assoc(ip, :interview),
      select: i.start_time)
    |> Repo.all)
    ++
    ((from sp in SlotPanelist,
      where: sp.panelist_login_name == ^panelist_login_name,
      join: i in assoc(sp, :slot),
      select: i.start_time)
    |> Repo.all)
  end

  def within_date_range(model, start_time, end_time) do
    from i in model, where: i.start_time >= ^start_time and i.start_time <= ^end_time
  end

  def now_or_in_next_seven_days(model) do
    start_of_today = Date.beginning_of_day(Date.now)
    seven_days_from_now = start_of_today |> Date.shift(days: 7)
    within_date_range(model, start_of_today, seven_days_from_now)
  end

  def default_order(model) do
    from i in model, order_by: [asc: i.start_time, asc: i.id]
  end

  def descending_order(model) do
    from i in model, order_by: [desc: i.start_time, asc: i.id]
  end
end
