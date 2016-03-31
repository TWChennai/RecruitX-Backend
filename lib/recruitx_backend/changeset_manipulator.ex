defmodule RecruitxBackend.ChangesetManipulator do
  alias RecruitxBackend.Repo
  alias RecruitxBackend.ChangesetErrorParser

  def insert(changesets) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, &(Repo.insert(&1)))
  end

  def update(changesets) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, &(Repo.update(&1)))
  end

  defp manipulate_changesets(true, changesets, db_operation) do
    {status, changeset} = Enum.reduce_while(changesets, [], fn i, _ ->
      {status, result} = db_operation.(i)
      if status == :error, do: throw {status, ChangesetErrorParser.to_json result}
      {:cont, {status, result}}
    end)
  end

  # TODO: Do not 'throw' return a tuple with an error code
  defp manipulate_changesets(false, changesets, _),
  do: throw{:changeset_error, changesets |> ChangesetErrorParser.to_json}

  defp check_changesets_validity(changesets),
  do: changesets |> Enum.all?(&(&1.valid?))
end
