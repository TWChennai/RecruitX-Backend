defmodule RecruitxBackend.SignUpDataContainer do

  defstruct panelist_login_name: "",
    candidate_ids_interviewed: [],
    my_previous_sign_up_start_times: [],
    signup_counts: [],
    panelist_experience: Decimal.new(0)
end
