defmodule RecruitxBackend.TimeRange do

  alias Timex.Date

  def get_previous_week do
    %{starting: Date.beginning_of_week(Date.now), ending: Date.end_of_week(Date.now) |> Date.shift(days: -2)}
  end

  def get_previous_month do
    day_from_previous_month = Date.now() |> Date.beginning_of_month |>  Date.shift(days: -1)
    %{starting: Date.beginning_of_month(day_from_previous_month), ending: Date.end_of_month(day_from_previous_month)}
  end
end
