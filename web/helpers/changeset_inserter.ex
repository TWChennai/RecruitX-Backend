defmodule RecruitxBackend.ChangesetInserter do
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.Repo

  def getChangesetErrorsInReadableFormat(changeset) do
    if Map.has_key?(changeset, :errors) do
      for n <- Keyword.keys(changeset.errors) do
        value = Keyword.get(changeset.errors, n)
        if is_tuple(value), do: value = elem(value, 0)
        %JSONErrorReason{field_name: n, reason: value}
      end
    else
      []
    end
  end

  def insertChangesets(changesets) do
    manipulate_changesets(changesets, :insert)
  end

  def updateChangesets(changesets) do
    manipulate_changesets(changesets, :update)
  end

  defp manipulate_changesets(changesets, action) do
    result = Enum.all?(changesets, fn(changeset) ->
      changeset.valid?
    end)
    if result do
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
    else
      errors = for n <- changesets, do: List.first(getChangesetErrorsInReadableFormat(n))
      errors_without_nil_values = Enum.filter(errors, fn(error) -> !is_nil(error) end)
      # TODO: Do not 'throw' return a tuple with an error code
      throw ({:changeset_error, errors_without_nil_values})
    end
  end
end
