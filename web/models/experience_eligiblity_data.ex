defmodule RecruitxBackend.ExperienceEligibilityData do

  defstruct panelist_experience: Decimal.new(0),
    max_experience_with_filter: [],
    interview_types_with_filter: [],
    experience_matrix_filters: []
end
