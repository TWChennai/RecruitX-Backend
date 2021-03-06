defmodule RecruitxBackend.Panel do
  import Ecto.Query

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewTypeRelativeEvaluator
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.SignUpEvaluator
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.TimexHelper

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
    start_of_today = TimexHelper.beginning_of_day(TimexHelper.utc_now())
    seven_days_from_now = start_of_today |> TimexHelper.add(7, :days)
    within_date_range(model, start_of_today, seven_days_from_now)
  end

  def default_order(model) do
    from i in model, order_by: [asc: i.start_time, asc: i.id]
  end

  def role_order(model) do
    from i in model, join: candi in assoc(i, :candidate), order_by: [asc: candi.role_id]
  end

  def descending_order(model) do
    from i in model, order_by: [desc: i.start_time, asc: i.id]
  end

  def add_signup_eligibity_for(slots, interviews, panelist_login_name, panelist_experience, panelist_role) do
    sign_up_data_container_for_interviews = SignUpEvaluator.populate_sign_up_data_container(panelist_login_name, Decimal.new(panelist_experience), panelist_role, false)
    sign_up_data_container_for_slots = SignUpEvaluator.populate_sign_up_data_container(panelist_login_name, Decimal.new(panelist_experience), panelist_role, true)

    interview_type_specfic_criteria = sign_up_data_container_for_interviews.interview_type_specfic_criteria
    ba_or_pm = Role.ba_and_pm_list
    interviews_with_signup_eligibility = Enum.reduce(interviews, [], fn(interview, acc) ->
      if is_visible(panelist_role, panelist_login_name, interview, interview_type_specfic_criteria, interview.candidate.role_id, ba_or_pm), do: acc ++ [put_sign_up_status(sign_up_data_container_for_interviews, interview, ba_or_pm)], else: acc
    end)
    Enum.reduce(slots, interviews_with_signup_eligibility, fn(slot, acc) ->
      if is_visible(panelist_role, panelist_login_name, slot, interview_type_specfic_criteria, slot.role_id, ba_or_pm), do: acc ++ [put_sign_up_status(sign_up_data_container_for_slots, slot, ba_or_pm)], else: acc
    end)
  end

  @lint [{Credo.Check.Refactor.FunctionArity, false}]
  defp is_visible(panelist_role, panelist_login_name, interview, interview_type_specfic_criteria, role_id, ba_or_pm) do
    (InterviewTypeRelativeEvaluator.is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria)
      and InterviewTypeRelativeEvaluator.is_allowed_panelist(interview, interview_type_specfic_criteria, panelist_login_name))
    or panelist_role == nil
    or role_id == panelist_role.id
    or (Role.is_ba_or_pm(role_id, ba_or_pm) and Role.is_ba_or_pm(panelist_role.id, ba_or_pm))
    or panelist_role.name == Role.ops
  end

  defp put_sign_up_status(sign_up_data_container, panel, ba_or_pm) do
    sign_up_evaluation_status = SignUpEvaluator.evaluate(sign_up_data_container, panel, ba_or_pm)
    panel = Map.put(panel, :signup_error, "")
    panel = if !sign_up_evaluation_status.valid? do
      {_, error} = sign_up_evaluation_status.errors |> List.first
      Map.put(panel, :signup_error, error)
    else
      panel
    end
    Map.put(panel, :signup, sign_up_evaluation_status.valid?)
  end

  def get_email_address(panelist_login_name) do
    panelist_login_name <> System.get_env("EMAIL_POSTFIX")
  end

  def format_names([]), do: ""

  def format_names(panelists) do
    Enum.reduce(panelists, "",
      fn(%{panelist_login_name: panelist_login_name}, accumulator) -> accumulator <> ", " <> panelist_login_name
      end)
      |> String.lstrip(?,)
      |> String.lstrip
  end
end
