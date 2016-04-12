defmodule RecruitxBackend.PreviousWeek do

  alias Timex.Date

  defstruct starting: Date.beginning_of_day(Date.now) |> Date.shift(days: -5),
            ending: Date.beginning_of_day(Date.now) |> Date.shift(days: -1)
end
