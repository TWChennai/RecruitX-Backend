defmodule RecruitxBackend.ChangesetInserter do
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.Repo

  def getChangesetErrorsInReadableFormat(changeset) do
    if Map.has_key?(changeset, :errors) do
      for n <- Keyword.keys(changeset.errors) do
        value = Keyword.get(changeset.errors, n)
        if is_tuple(value) do
          value = elem(value, 0)
        end
        %JSONErrorReason{field_name: n, reason: value}
      end
    else
      []
    end
  end

  def insertChangesets(changesets) do
    result = Enum.all?(changesets, fn(changeset) ->
      changeset.valid?
    end)
    if result do
      {status, changeset} = Enum.reduce_while(changesets, [], fn i, _ ->
        {status, result} = Repo.insert(i)
        acc = {status, result}
        if (status == :error) do
          throw {status, getChangesetErrorsInReadableFormat(result)}
        else
          {:cont, acc}
        end
      end)
    else
      errors = for n <- changesets, do: List.first(getChangesetErrorsInReadableFormat(n))
      errors_without_nil_values = Enum.filter(errors, fn(error) -> error != nil end)
      throw ({:changeset_error, errors_without_nil_values})
    end
  end
end