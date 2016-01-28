defmodule RecruitxBackend.QueryFilter do
  alias Ecto.Changeset

  # TODO: For now, only filters on exact match, will need something similar to LIKE matches for strings
  # For eg: http://localhost:4000/candidates?name=Maha
  def filter(query, model, params, filters) do
    import Ecto.Query, only: [where: 2]

    where_clauses = cast(model, params, filters) |> Map.to_list
    query |> where(^where_clauses)
  end

  def cast(model, params, filters) do
    Changeset.cast(model, params, [], filters) |> Map.fetch!(:changes)
  end
end
