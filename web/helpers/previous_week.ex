defmodule RecruitxBackend.PreviousWeek do

  alias Timex.Date

  def get do
    %{starting: Date.beginning_of_week(Date.now), ending: Date.end_of_week(Date.now) |> Date.shift(days: -2)}
  end
end
