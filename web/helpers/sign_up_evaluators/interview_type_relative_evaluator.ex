defmodule RecruitxBackend.InterviewTypeRelativeEvaluator do

  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.Repo

  def evaluate(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_login_name, panelist_role, interview) do
    sign_up_evaluation_status
    |> is_eligible_based_on_interview_type(interview_type_specfic_criteria, panelist_login_name, interview)
    |> is_eligible_based_on_role(interview_type_specfic_criteria, panelist_role, interview)
  end

  defp is_eligible_based_on_interview_type(%{valid?: false} = sign_up_evaluation_status, _, _, _), do: sign_up_evaluation_status

  defp is_eligible_based_on_interview_type(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_login_name, interview) do
    if is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria)
    and !is_allowed_panelist(interview, interview_type_specfic_criteria, panelist_login_name), do:
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are not eligible to sign up for this interview"})
    sign_up_evaluation_status
  end

  defp is_eligible_based_on_role(%{valid?: false} = sign_up_evaluation_status, _, _, _), do: sign_up_evaluation_status

  defp is_eligible_based_on_role(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_role, interview) do
    interview = Repo.preload interview, :candidate
    if !is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria)
    and (panelist_role |> is_nil or panelist_role.id != interview.candidate.role_id), do:
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are not eligible to sign up for this interview"})
    sign_up_evaluation_status
  end

  def is_interview_type_with_specific_panelists(interview, interview_type_specfic_criteria), do:
    interview.interview_type_id in Map.keys(interview_type_specfic_criteria)

  def is_allowed_panelist(interview, interview_type_specfic_criteria, panelist_login_name),  do:
    Enum.member?(Map.get(interview_type_specfic_criteria, interview.interview_type_id), panelist_login_name)
end
