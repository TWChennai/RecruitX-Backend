defmodule RecruitxBackend.QueryFilter do
  @moduledoc """
  QueryFilter is a module containing utility methods to deal with Ecto.Query objects
  """

  alias Ecto.Query

  @doc """
  #filter is to be used to convert from a hash containing filters for the specified model and query.
  For each key in the filters hash, if the value is an array, the resulting query will perform an 'OR' condition;
  and if there are multiple keys, each key is added using an 'AND' condition.
  Any keys that are not mapped to a field will be discarded

  Example usage:
      query = Ecto.Query.from c in Candidate
      filters = %{first_name: ["Subha%", "Maha%"], role_id: [4, 2], dummy: 1}
      model = Candidate

      QueryFilter.filter(query, filters, model)
    will result in a sql similar to
      select * from candidates
      where first_name ILIKE ANY('Subha%', 'Maha%')
      AND role_id in (4, 2)
  """
  def filter(query, filters, model) do
    import Query, only: [from: 2, where: 2]

    Enum.reduce(Map.keys(filters), query, fn(key, acc) ->
      value = Map.get(filters, key)
      field_value = if is_list(value), do: value, else: [value]
      case model.__changeset__[key] do
        nil ->
          acc
        :string ->
          from c in acc, where: fragment("? ILIKE ANY(?)", field(c, ^key) , ^field_value)
        _ ->
          from c in acc, where: field(c, ^key) in ^field_value
        end
    end)
  end
end
