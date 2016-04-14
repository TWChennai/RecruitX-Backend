defmodule RecruitxBackend.TimexHelper do
  alias Timex.Date
  alias Timex.Timezone
  alias Timex.DateFormat

  @time_zone_name "Asia/Kolkata"

  def compare(time_one, time_two) do
    Date.compare(time_one, time_two) >= 0;
  end

  def format(input_date_time, date_format) do
    {:ok , interview_date} = input_date_time
                             |> Timezone.convert(@time_zone_name)
                             |> DateFormat.format(date_format, :strftime)
    interview_date
  end
end
