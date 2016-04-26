defmodule RecruitxBackend.TestHelpers do
  alias Timex.Date

  def conn_with_dummy_authorization() do
    Plug.Conn.put_req_header(Phoenix.ConnTest.conn(), "authorization", System.get_env("API_KEY"))
  end

  def convertKeysFromAtomsToStrings(input) do
    for {key, val} <- input, into: %{}, do: {to_string(key), val}
  end

  def compare_fields( map1, map2, fields) do
    Enum.all?(fields, fn(field) -> Map.get(map1, field) == Map.get(map2, field) end)
  end

  def get_start_of_current_week,
  do: Date.now |> Date.beginning_of_week |> Date.shift(mins: 1)

  def get_start_of_previous_month,
  do: Date.now |> Date.beginning_of_month |> Date.shift(days: -2)

  def get_start_of_previous_quarter,
  do: Date.now |> Date.beginning_of_quarter |> Date.shift(days: -2)

  def get_start_of_next_week,
  do: Date.now |> Date.end_of_week |> Date.shift(mins: 1)
end
