defmodule RecruitxBackend.ChangesetErrorParser do

  alias RecruitxBackend.JSONErrorReason

  def to_json(changesets) when is_list(changesets) do
    errors = for n <- changesets, do: List.first(to_json(n))
    Enum.filter(errors, fn(error) -> !is_nil(error) end)
  end

  def to_json(%{errors: errors}), do: recursive_caller errors

  def to_json(_), do: []

  defp recursive_caller([h | t]), do: [parse_error(h) | recursive_caller(t)]

  defp recursive_caller([]), do: []

  defp parse_error({n, value}) when is_tuple(value), do: parse_error({n, elem(value, 0)})

  defp parse_error({n, value}), do: %JSONErrorReason{field_name: n, reason: value}
end
