defmodule RecruitxBackend.TestHelpers do

  def conn_with_dummy_authorization() do
    Plug.Conn.put_req_header(Phoenix.ConnTest.conn(),"authorization", "recruitx")
  end

  def convertKeysFromAtomsToStrings(input) do
    for {key, val} <- input, into: %{}, do: {to_string(key), val}
  end

  def compare_fields( map1, map2, fields) do
    Enum.all?(fields, fn(field) -> Map.get(map1, field) == Map.get(map2, field) end)
  end
end
