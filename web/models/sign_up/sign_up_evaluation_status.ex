defmodule RecruitxBackend.SignUpEvaluationStatus do
  defstruct valid?: true, errors: []

  def add_errors(sign_up_evaluation_status, error),
    do: Map.merge(sign_up_evaluation_status , %{errors: sign_up_evaluation_status.errors ++ [error], valid?: false})
end
