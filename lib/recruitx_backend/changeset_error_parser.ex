defmodule RecruitxBackend.ChangesetErrorParser do

  alias RecruitxBackend.JSONErrorReason

  def to_json(changesets = [h | t]) when is_list(changesets),
  do: to_json(h) ++ to_json(t)

  def to_json(%{errors: errors}), do: recursive_caller errors

  def to_json(_), do: []

  defp recursive_caller(input, initial_value \\ [])

  defp recursive_caller([h | t], result), do: recursive_caller(t, result ++ [parse_error(h)])

  defp recursive_caller([], result), do: result

  defp parse_error({n, value}) when is_tuple(value), do: parse_error({n, elem(value, 0)})

  defp parse_error({n, value}), do: %JSONErrorReason{field_name: n, reason: value}
end
