defmodule RecruitxBackend.ExperienceMatrixRelativeEvaluator do

  alias RecruitxBackend.SignUpEvaluationStatus

  def evaluate(sign_up_evaluation_status, experience_eligibility_criteria, interview) do
    sign_up_evaluation_status
    |> is_valid_against_experience_matrix(experience_eligibility_criteria, interview.candidate.experience, interview.interview_type_id)
  end

  defp is_valid_against_experience_matrix(sign_up_evaluation_status, experience_eligibility_criteria, candidate_experience, interview_type_id) do
    if sign_up_evaluation_status.valid? and !is_eligible(candidate_experience, interview_type_id, experience_eligibility_criteria) do
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:experience_matrix, "The panelist does not have enough experience"})
    end
    sign_up_evaluation_status
  end

  def is_eligible(candidate_experience, interview_type_id, eligiblity_criteria) do
    to_float(eligiblity_criteria.panelist_experience) > to_float(eligiblity_criteria.max_experience_with_filter)
    or !Enum.member?(eligiblity_criteria.interview_types_with_filter, interview_type_id)
    or eligiblity_criteria.experience_matrix_filters |> is_eligible_based_on_filter(candidate_experience,interview_type_id)
  end

  defp is_eligible_based_on_filter(experience_matrix_filters, candidate_experience, interview_type_id) do
    Enum.any?(experience_matrix_filters, fn({eligible_candidate_experience, eligible_interview_type_id}) ->
      interview_type_id == eligible_interview_type_id and to_float(candidate_experience) <= to_float(eligible_candidate_experience)
    end)
  end

  defp to_float(input), do: Float.parse(input |> Decimal.to_string())
end
