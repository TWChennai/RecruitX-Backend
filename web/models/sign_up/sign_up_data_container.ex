defmodule RecruitxBackend.SignUpDataContainer do

  alias RecruitxBackend.ExperienceEligibilityData

  defstruct panelist_login_name: "",
    candidate_ids_interviewed: [],
    my_previous_sign_up_start_times: [],
    signup_counts: [],
    experience_eligibility_criteria: %ExperienceEligibilityData{},
    interview_type_specfic_criteria: %{},
    panelist_role: nil
end
