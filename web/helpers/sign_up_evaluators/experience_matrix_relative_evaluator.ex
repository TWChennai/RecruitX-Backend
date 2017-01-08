defmodule RecruitxBackend.ExperienceMatrixRelativeEvaluator do

  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.Repo
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.SlotPanelist

  @lower_bound "LB"
  @upper_bound "UB"

  import Ecto.Query, only: [from: 2, where: 2]

  def evaluate(sign_up_evaluation_status, %{experience_eligibility_criteria: experience_eligibility_criteria, panelist_role: panelist_role}, interview, is_slot) do
    experience  = calculate_experience(interview, is_slot)
    sign_up_evaluation_status
    |> is_eligible_without_LB_and_UB_filters(interview.interview_type_id, experience_eligibility_criteria, panelist_role)
    |> is_eligible_with_LB_filters(experience_eligibility_criteria.experience_matrix_filters, experience, interview.interview_type_id)
    |> is_eligible_with_UB_filters(experience_eligibility_criteria.experience_matrix_filters, experience, interview.interview_type_id)
    |> find_the_best_fit_criteria(interview.id, is_slot)
  end

  defp calculate_experience(slot, true), do: slot.average_experience

  defp calculate_experience(interview, false) do
    interview = Repo.preload interview, :candidate
    interview.candidate.experience
  end

  defp is_eligible_without_LB_and_UB_filters(%{valid?: true} = sign_up_evaluation_status, interview_type_id,  experience_eligibility_criteria, panelist_role) do
    result = !Enum.member?(experience_eligibility_criteria.interview_types_with_filter,       interview_type_id)
              or !Enum.member?(experience_eligibility_criteria.role_ids_with_filter, panelist_role.id)
              or to_float(experience_eligibility_criteria.panelist_experience) > to_float(experience_eligibility_criteria.max_experience_with_filter)
    if result, do: sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@lower_bound)
    sign_up_evaluation_status
  end

  defp is_eligible_without_LB_and_UB_filters(%{valid?: false} = sign_up_evaluation_status, _interview_type_id,  _experience_eligibility_criteria, _panelist_role), do: sign_up_evaluation_status

  defp is_eligible_with_LB_filters(%{valid?: true, satisfied_criteria: ""} = sign_up_evaluation_status, experience_matrix_filters, candidate_experience, interview_type_id) do
    result = Enum.any?(experience_matrix_filters, fn({eligible_candidate_lower_experience, _eligible_candidate_upper_experience, eligible_interview_type_id}) -> interview_type_id == eligible_interview_type_id and to_float(candidate_experience) <= to_float(eligible_candidate_lower_experience)
    end)
    if result, do: sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@lower_bound)
    sign_up_evaluation_status
  end

  defp is_eligible_with_LB_filters(sign_up_evaluation_status, _, _, _), do: sign_up_evaluation_status

  defp is_eligible_with_UB_filters(%{valid?: true, satisfied_criteria: ""} = sign_up_evaluation_status, experience_matrix_filters, candidate_experience, interview_type_id) do
    result = Enum.any?(experience_matrix_filters, fn({_eligible_candidate_lower_experience,eligible_candidate_upper_experience, eligible_interview_type_id}) -> interview_type_id == eligible_interview_type_id and to_float(candidate_experience) <= to_float(eligible_candidate_upper_experience)
    end)
    if result do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@upper_bound)
    else
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:experience_matrix, "The panelist does not have enough experience"})
    end
  end

  defp is_eligible_with_UB_filters(sign_up_evaluation_status, _experience_matrix_filters, _candidate_experience, _interview_type_id), do: sign_up_evaluation_status

  defp get_existing_satisfied_criteria(interview_id, true), do: (from i in SlotPanelist, select: i.satisfied_criteria, where: i.slot_id == ^interview_id)

  defp get_existing_satisfied_criteria(interview_id, false), do: (from i in InterviewPanelist, select: i.satisfied_criteria, where: i.interview_id == ^interview_id)

  defp find_the_best_fit_criteria(%{valid?: true} = sign_up_evaluation_status, interview_id, is_slot) do
    existing_satisfied_criteria = get_existing_satisfied_criteria(interview_id, is_slot) |> Repo.one
    sign_up_evaluation_status |> update_best_satisfied_criteria(sign_up_evaluation_status.satisfied_criteria, sign_up_evaluation_status.satisfied_criteria == existing_satisfied_criteria)
  end

  defp find_the_best_fit_criteria(%{valid?: false} = sign_up_evaluation_status, _interview_id, _is_slot), do: sign_up_evaluation_status

  defp update_best_satisfied_criteria(sign_up_evaluation_status, @lower_bound, _) do
    sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@lower_bound)
  end

  defp update_best_satisfied_criteria(sign_up_evaluation_status, @upper_bound, true) do
    sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:experience_matrix, "Panelist with the required eligibility already met"})
  end

  defp update_best_satisfied_criteria(sign_up_evaluation_status, @upper_bound, false) do
    sign_up_evaluation_status |> SignUpEvaluationStatus.add_satisfied_criteria(@upper_bound)
  end

  defp to_float(input), do: Float.parse(input |> Decimal.to_string())
end
