# TODO: Should this be moved into the lib folder so that its loaded only once?
defmodule RecruitxBackend.ChangesetManipulator do
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.Repo

  def insertChangesets(changesets) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, :insert)
  end

  def updateChangesets(changesets) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, :update)
  end

  defp manipulate_changesets(true, changesets, action),
  do: changesets |> insert_changesets(action)

  defp manipulate_changesets(false, changesets, _),
  do: changesets |> get_changesets_error

  defp check_changesets_validity(changesets),
  do: changesets |> Enum.all?(&(&1.valid?))

  defp insert_changesets(changesets, action) do
    {status, changeset} = Enum.reduce_while(changesets, [], fn i, _ ->
      {status, result} = case action do
        :insert -> Repo.insert(i)
        :update -> Repo.update(i)
      end
      acc = {status, result}
      if (status == :error) do
        # TODO: Do not 'throw' return a tuple with an error code
        throw {status, getChangesetErrorsInReadableFormat(result)}
      else
        {:cont, acc}
      end
    end)
  end

  defp get_changesets_error(changesets) do
    errors = for n <- changesets, do: List.first(getChangesetErrorsInReadableFormat(n))
    errors_without_nil_values = Enum.filter(errors, fn(error) -> !is_nil(error) end)
    # TODO: Do not 'throw' return a tuple with an error code
    throw ({:changeset_error, errors_without_nil_values})
  end

  def getChangesetErrorsInReadableFormat(%{errors: errors}) do
    for n <- Keyword.keys(errors) do
      value = Keyword.get(errors, n)
      if is_tuple(value), do: value = elem(value, 0)
      %JSONErrorReason{field_name: n, reason: value}
    end
  end

  def getChangesetErrorsInReadableFormat(_),
  do: []
end
