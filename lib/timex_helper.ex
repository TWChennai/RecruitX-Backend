defmodule RecruitxBackend.TimexHelper do
  @time_zone_name "Asia/Kolkata"
  @time_zone_string_length 19

  def add_timezone_if_not_present(%{start_time: <<start_time::binary-size(@time_zone_string_length)>>} = params) do
    start_time = start_time |> String.replace(" ", "T")
    unless String.ends_with?(start_time, "Z"), do: start_time = start_time <> "Z"
    Map.put(params, :start_time, start_time)
  end

  def add_timezone_if_not_present(without_start_time), do: without_start_time

  def utc_now() do
    Timex.now()
  end

  def add(start_time, minutes, :minutes) do
    Timex.add(start_time, Timex.Duration.from_minutes(minutes))
  end

  def add(start_time, hours, :hours) do
    Timex.add(start_time, Timex.Duration.from_hours(hours))
  end

  def add(start_time, days, :days) do
    Timex.add(start_time, Timex.Duration.from_days(days))
  end

  def add(start_time, months, :months) do
    Timex.add(start_time, Timex.Duration.from_days(months * 30))
  end

  def compare(time_one, time_two) do
    Timex.compare(time_one, time_two) >= 0
  end

  def beginning_of_day(time) do
    Timex.beginning_of_day(time)
  end

  def end_of_day(time) do
    Timex.end_of_day(time)
  end

  def beginning_of_week(time) do
    Timex.beginning_of_week(time)
  end

  def end_of_week(time) do
    Timex.end_of_week(time)
  end

  def beginning_of_month(time) do
    Timex.beginning_of_month(time)
  end

  def end_of_month(time) do
    Timex.end_of_month(time)
  end

  def beginning_of_quarter(time) do
    Timex.beginning_of_quarter(time)
  end

  def end_of_quarter(time) do
    Timex.end_of_quarter(time)
  end

  def from_epoch(options) do
    Timex.set(Timex.to_datetime(Timex.epoch), options)
  end

  def parse(input_date_time, format) do
    {:ok, result} = Timex.parse(input_date_time, format, :strftime)
    result |> Timex.Timezone.convert("UTC")
  end

  def format(input_date_time, date_format) do
    {:ok, formatted} = input_date_time |> Timex.format(date_format, :strftime)
    formatted
  end

  def format_with_timezone(input_date_time, date_format) do
    time_in_new_zone = input_date_time |> Timex.Timezone.convert(@time_zone_name)
    {:ok, formatted} = time_in_new_zone |> Timex.format(date_format, :strftime)
    formatted
  end
end
