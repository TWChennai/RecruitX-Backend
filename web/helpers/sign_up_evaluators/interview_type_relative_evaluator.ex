defmodule RecruitxBackend.InterviewTypeRelativeEvaluator do

  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.Role
  alias RecruitxBackend.Repo

  @lint {Credo.Check.Refactor.FunctionArity, false}
  def evaluate(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_login_name, panelist_role, interview, is_slot, ba_or_pm) do
    sign_up_evaluation_status
    |> is_eligible_based_on_interview_type(interview_type_specfic_criteria, panelist_login_name, interview)
    |> is_eligible_based_on_role(interview_type_specfic_criteria, panelist_role, interview, is_slot, ba_or_pm)
  end

  defp is_eligible_based_on_interview_type(%{valid?: false} = sign_up_evaluation_status, _, _, _), do: sign_up_evaluation_status

  defp is_eligible_based_on_interview_type(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_login_name, interview) do
    if is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria)
    and !is_allowed_panelist(interview, interview_type_specfic_criteria, panelist_login_name) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are not eligible to sign up for this interview"})
    else
      sign_up_evaluation_status
    end
  end

  defp is_eligible_based_on_role(%{valid?: false} = sign_up_evaluation_status, _, _, _, _, _), do: sign_up_evaluation_status

  @lint [{Credo.Check.Refactor.FunctionArity, false}]
  defp is_eligible_based_on_role(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_role, interview, false, ba_or_pm) do
    interview = Repo.preload interview, :candidate
    if !is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria)
    and (panelist_role |> is_nil or !(Role.is_ba_or_pm(panelist_role.id, ba_or_pm) and Role.is_ba_or_pm(interview.candidate.role_id, ba_or_pm)) and panelist_role.id != interview.candidate.role_id) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are not eligible to sign up for this interview"})
    else
      sign_up_evaluation_status
    end
  end

  @lint [{Credo.Check.Refactor.FunctionArity, false}]
  defp is_eligible_based_on_role(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_role, slot, true, ba_or_pm) do
    if !is_interview_type_with_specific_panelists(slot, interview_type_specfic_criteria)
    and (panelist_role |> is_nil or !(Role.is_ba_or_pm(panelist_role.id, ba_or_pm) and Role.is_ba_or_pm(slot.role_id, ba_or_pm)) and panelist_role.id != slot.role_id) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are not eligible to sign up for this slot"})
    else
      sign_up_evaluation_status
    end
  end

  def is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria), do:
    interview.interview_type_id in Map.keys(interview_type_specfic_criteria)

  def is_allowed_panelist(interview, interview_type_specfic_criteria, panelist_login_name),  do:
    Enum.member?(Map.get(interview_type_specfic_criteria, interview.interview_type_id), panelist_login_name)
end
