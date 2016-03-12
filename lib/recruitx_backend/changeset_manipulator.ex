defmodule RecruitxBackend.ChangesetManipulator do
  alias RecruitxBackend.Repo
  alias RecruitxBackend.ChangesetErrorParser

  def insert(changesets) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, :insert)
  end

  def update(changesets) do
    changesets
    |> check_changesets_validity
    |> manipulate_changesets(changesets, :update)
  end

  defp manipulate_changesets(true, changesets, action),
  do: changesets |> insert_changesets(action)

  # TODO: Do not 'throw' return a tuple with an error code
  defp manipulate_changesets(false, changesets, _),
  do: throw{:changeset_error, changesets |> ChangesetErrorParser.to_json}

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
        throw {status, ChangesetErrorParser.to_json result}
      else
        {:cont, acc}
      end
    end)
  end
end
