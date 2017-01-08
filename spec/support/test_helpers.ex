defmodule RecruitxBackend.TestHelpers do
  alias RecruitxBackend.TimexHelper

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
  do: TimexHelper.utc_now() |> TimexHelper.beginning_of_week |> TimexHelper.add(1, :minutes)

  def get_date_of_previous_month,
  do: TimexHelper.utc_now() |> TimexHelper.beginning_of_month |> TimexHelper.add(-2, :days)

  def get_date_of_previous_quarter,
  do: TimexHelper.utc_now() |> TimexHelper.beginning_of_quarter |> TimexHelper.add(-2, :days)

  def get_start_of_next_week,
  do: TimexHelper.utc_now() |> TimexHelper.end_of_week |> TimexHelper.add(1, :minutes)
end
