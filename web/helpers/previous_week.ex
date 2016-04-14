defmodule RecruitxBackend.PreviousWeek do

  alias Timex.Date

  # TODO: How will this logic work for any weekday? Or are we targetting "the last 5 working days"?
  # Instead, should we not be using `Date.beginning_of_week`?
  def get do
    %{starting: Date.beginning_of_day(Date.now) |> Date.shift(days: -5), ending: Date.beginning_of_day(Date.now) |> Date.shift(days: -1)}
  end
end
