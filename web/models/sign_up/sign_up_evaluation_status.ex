defmodule RecruitxBackend.SignUpEvaluationStatus do
  defstruct valid?: true, errors: [], satisfied_criteria: ""

  def add_errors(sign_up_evaluation_status, error),
    do: Map.merge(sign_up_evaluation_status , %{errors: sign_up_evaluation_status.errors ++ [error], valid?: false})

  def add_satisfied_criteria(sign_up_evaluation_status, satisfied_criteria),
    do: Map.merge(sign_up_evaluation_status , %{satisfied_criteria: satisfied_criteria})
end
