defmodule RecruitxBackend.InterviewTypeRelativeEvaluator do

  alias RecruitxBackend.SignUpEvaluationStatus

  def evaluate(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_login_name, interview) do
    sign_up_evaluation_status
    |> is_eligible_to_take_based_on_interview_type(interview_type_specfic_criteria, panelist_login_name, interview)
  end

  defp is_eligible_to_take_based_on_interview_type(sign_up_evaluation_status, %{valid?: false}, _, _, _), do: sign_up_evaluation_status

  defp is_eligible_to_take_based_on_interview_type(sign_up_evaluation_status, interview_type_specfic_criteria, panelist_login_name, interview) do
    if interview.interview_type_id in Map.keys(interview_type_specfic_criteria) and !Enum.member?(Map.get(interview_type_specfic_criteria, interview.interview_type_id), panelist_login_name) do
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are not eligible to sign up for this interview"})
    end
    sign_up_evaluation_status
  end
end
