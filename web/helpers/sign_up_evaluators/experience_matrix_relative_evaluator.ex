defmodule RecruitxBackend.ExperienceMatrixRelativeEvaluator do

  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.Repo

  @lower_bound "LB"
  @upper_bound "UB"

  require Logger

  def evaluate(sign_up_evaluation_status, experience_eligibility_criteria, interview) do
    interview = Repo.preload interview, :candidate
    sign_up_evaluation_status
    |> is_valid_against_experience_matrix(experience_eligibility_criteria, interview.candidate.experience, interview.interview_type_id)
  end

  defp is_valid_against_experience_matrix(sign_up_evaluation_status, experience_eligibility_criteria, candidate_experience, interview_type_id) do
    if sign_up_evaluation_status.valid? do
      if is_eligible_without_LB_and_UB_filters(candidate_experience, interview_type_id, experience_eligibility_criteria) do
        sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@lower_bound)
      else
        if is_eligible_with_LB_filters(experience_eligibility_criteria.experience_matrix_filters, candidate_experience, interview_type_id) do
          sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@lower_bound)
        else
          if is_eligible_with_UB_filters(experience_eligibility_criteria.experience_matrix_filters, candidate_experience, interview_type_id) do
            sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@upper_bound)
          else
            sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:experience_matrix, "The panelist does not have enough experience"})
          end
        end
      end
    end
    sign_up_evaluation_status
  end

  defp is_eligible_without_LB_and_UB_filters(candidate_experience, interview_type_id, experience_eligibility_criteria) do
    result = to_float(experience_eligibility_criteria.panelist_experience) > to_float(experience_eligibility_criteria.max_experience_with_filter)
    or !Enum.member?(experience_eligibility_criteria.interview_types_with_filter, interview_type_id)
    Logger.info("Panelist exp: #{experience_eligibility_criteria.panelist_experience} Candidate exp:#{candidate_experience} interview_type_id: #{interview_type_id} result: #{result}")
    result
  end

  defp is_eligible_with_LB_filters(experience_matrix_filters, candidate_experience, interview_type_id) do
    Enum.any?(experience_matrix_filters, fn({eligible_candidate_lower_experience, _eligible_candidate_upper_experience, eligible_interview_type_id}) ->
      interview_type_id == eligible_interview_type_id and to_float(candidate_experience) <= to_float(eligible_candidate_lower_experience)
    end)
  end

  defp is_eligible_with_UB_filters(experience_matrix_filters, candidate_experience, interview_type_id) do
    Enum.any?(experience_matrix_filters, fn({_eligible_candidate_lower_experience, eligible_candidate_upper_experience, eligible_interview_type_id}) ->
      interview_type_id == eligible_interview_type_id and to_float(candidate_experience) <= to_float(eligible_candidate_upper_experience)
    end)
  end

  defp to_float(input), do: Float.parse(input |> Decimal.to_string())
end
