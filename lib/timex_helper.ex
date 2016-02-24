defmodule RecruitxBackend.TimexHelper do
  alias Timex.Date

  def compare(time_one, time_two) do
    Date.compare(time_one, time_two) >= 0;
  end
end
