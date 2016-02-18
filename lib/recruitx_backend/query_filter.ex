defmodule RecruitxBackend.QueryFilter do
  alias Ecto.Query

  #query = Ecto.Query.from c in Candidate
  #filters = %{name: ["Subha%", "Maha%"],role_id: [4,2], dummy: [1]}
  #model = Candidate
  def filter(query, filters, model) do
    import Query, only: [from: 2, where: 2]

    Enum.reduce(Map.keys(filters), query, fn(key, acc) ->
      value = Map.get(filters, key)
      field_value = if is_list(value), do: value, else: [value]
      case {model.__changeset__[key]} do
        {nil} ->
          acc
        {:string} ->
          from c in acc, where: fragment("? ILIKE ANY(?)", field(c, ^key) , ^field_value)
        _ ->
          from c in acc, where: field(c, ^key) in ^field_value
        end
    end)
  end
end
