defmodule RecruitxBackend.SignUpEvaluator do

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.SignUpDataContainer
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.ExperienceEligibilityData
  alias RecruitxBackend.InterviewRelativeEvaluator
  alias RecruitxBackend.ExperienceMatrixRelativeEvaluator
  alias RecruitxBackend.InterviewTypeRelativeEvaluator
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Role
  alias RecruitxBackend.Panel

  @ops Role.ops

  def populate_sign_up_data_container(panelist_login_name, panelist_experience, panelist_role, is_slot \\ false) do
    candidate_ids_interviewed = InterviewPanelist.get_candidate_ids_interviewed_by(panelist_login_name)
    my_previous_sign_up_start_times = Panel.get_start_times_interviewed_by(panelist_login_name)
    signup_counts = get_signup_counts(is_slot)
    retrieved_panelist_role = Role.retrieve_by_name(panelist_role)
    %SignUpDataContainer{panelist_login_name: panelist_login_name,
    candidate_ids_interviewed: candidate_ids_interviewed,
    my_previous_sign_up_start_times: my_previous_sign_up_start_times,
    signup_counts: signup_counts,
    experience_eligibility_criteria: populate_experience_eligiblity_criteria(panelist_experience, retrieved_panelist_role),
    interview_type_specfic_criteria: InterviewType.get_type_specific_panelists,
    panelist_role: retrieved_panelist_role,
    interview_type_based_sign_up_limits: InterviewType.get_sign_up_limits,
    slot: is_slot
    }
  end

  defp get_signup_counts(false), do: (InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all)

  defp get_signup_counts(true), do: (SlotPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all)

  defp populate_experience_eligiblity_criteria(panelist_experience, panelist_role) do
    %ExperienceEligibilityData{panelist_experience: panelist_experience,
      max_experience_with_filter: panelist_role |> ExperienceMatrix.get_max_experience_with_filter,
      interview_types_with_filter: ExperienceMatrix.get_interview_types_with_filter,
      experience_matrix_filters: (ExperienceMatrix.filter(panelist_experience, panelist_role)),
      role_ids_with_filter: ExperienceMatrix.get_role_ids_with_filter
    }
  end

  def evaluate(%{ panelist_role: %{name: @ops}} = sign_up_data_container , interview) do
    %SignUpEvaluationStatus{}
    |> InterviewRelativeEvaluator.evaluate(sign_up_data_container, interview)
  end

  def evaluate(sign_up_data_container, interview) do
    %SignUpEvaluationStatus{}
    |> InterviewTypeRelativeEvaluator.evaluate(sign_up_data_container.interview_type_specfic_criteria, sign_up_data_container.panelist_login_name, sign_up_data_container.panelist_role, interview, sign_up_data_container.slot)
    |> InterviewRelativeEvaluator.evaluate(sign_up_data_container, interview)
    |> ExperienceMatrixRelativeEvaluator.evaluate(sign_up_data_container, interview, sign_up_data_container.slot)
  end
end
