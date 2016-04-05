defmodule RecruitxBackend.SignUpEvaluator do

  alias RecruitxBackend.InterviewPanelist
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

  def populate_sign_up_data_container(panelist_login_name, panelist_experience, panelist_role) do
    {candidate_ids_interviewed, my_previous_sign_up_start_times} = InterviewPanelist.get_candidate_ids_and_start_times_interviewed_by(panelist_login_name)
    signup_counts = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all
    retrieved_panelist_role = Role.retrieve_by_name(panelist_role)
    %SignUpDataContainer{panelist_login_name: panelist_login_name,
    candidate_ids_interviewed: candidate_ids_interviewed,
    my_previous_sign_up_start_times: my_previous_sign_up_start_times,
    signup_counts: signup_counts,
    experience_eligibility_criteria: populate_experience_eligiblity_criteria(panelist_experience, retrieved_panelist_role),
    interview_type_specfic_criteria: InterviewType.get_type_specific_panelists,
    panelist_role: retrieved_panelist_role
    }
  end

  defp populate_experience_eligiblity_criteria(panelist_experience, panelist_role) do
    %ExperienceEligibilityData{panelist_experience: panelist_experience,
      max_experience_with_filter: panelist_role |> ExperienceMatrix.get_max_experience_with_filter,
      interview_types_with_filter: ExperienceMatrix.get_interview_types_with_filter,
      experience_matrix_filters: (ExperienceMatrix.filter(panelist_experience, panelist_role))
    }
  end

  def evaluate(sign_up_data_container, interview) do
    %SignUpEvaluationStatus{}
    |> InterviewTypeRelativeEvaluator.evaluate(sign_up_data_container.interview_type_specfic_criteria, sign_up_data_container.panelist_login_name, sign_up_data_container.panelist_role, interview)
    |> InterviewRelativeEvaluator.evaluate(sign_up_data_container, interview)
    |> ExperienceMatrixRelativeEvaluator.evaluate(sign_up_data_container.experience_eligibility_criteria, interview)
  end
end
