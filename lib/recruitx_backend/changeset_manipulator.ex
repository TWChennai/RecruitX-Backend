# TODO: Remove this file when the codebase has been converted to use Ecto.Multi
defmodule RecruitxBackend.ChangesetManipulator do
  alias RecruitxBackend.ChangesetErrorParser

  def validate_and([], _insert_or_update), do: []
  def validate_and(changesets, insert_or_update) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, insert_or_update, :optional)
  end

  defp manipulate_changesets(false, changesets, _, _), do: {false, changesets |> ChangesetErrorParser.to_json}
  defp manipulate_changesets(status, [], _db_operation, result), do: {status, result}
  defp manipulate_changesets(true, [head | changesets], db_operation, _result) do
      case db_operation.(head) do
        {:ok, result} -> manipulate_changesets(true, changesets, db_operation, result)
        {:error, result} -> {false, result |> ChangesetErrorParser.to_json}
      end
  end

  defp check_changesets_validity(changesets), do: changesets |> Enum.all?(&(&1.valid?))
end
