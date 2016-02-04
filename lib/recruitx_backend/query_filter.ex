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

  require Ecto.Query
  #query = Ecto.Query.from c in Candidate
  #filters = %{name: ["Subha", "Maha"],role_id: [4,2]}
  def filter_new(query, filters) do
    Enum.reduce(Map.keys(filters), query, fn(key,acc) ->
      field_value = Map.get(filters, key)
      Ecto.Query.from c in acc, where: field(c,^key) in ^field_value
    end)
  end
end
