defmodule RecruitxBackend.TimexHelper do
  @time_zone_name "Asia/Kolkata"

  def utc_now() do
    Timex.Date.now()
  end

  def add(start_time, minutes, :minutes) do
    Timex.Date.shift(start_time, mins: minutes)
  end

  def add(start_time, hours, :hours) do
    Timex.Date.shift(start_time, hours: hours)
  end

  def add(start_time, days, :days) do
    Timex.Date.shift(start_time, days: days)
  end

  def add(start_time, months, :months) do
    Timex.Date.shift(start_time, months: months)
  end

  def compare(time_one, time_two) do
    Timex.Date.compare(time_one, time_two) >= 0
  end

  def beginning_of_day(time) do
    Timex.Date.beginning_of_day(time)
  end

  def end_of_day(time) do
    Timex.Date.end_of_day(time)
  end

  def beginning_of_week(time) do
    Timex.Date.beginning_of_week(time)
  end

  def end_of_week(time) do
    Timex.Date.end_of_week(time)
  end

  def beginning_of_month(time) do
    Timex.Date.beginning_of_month(time)
  end

  def end_of_month(time) do
    Timex.Date.end_of_month(time)
  end

  def beginning_of_quarter(time) do
    Timex.Date.beginning_of_quarter(time)
  end

  def end_of_quarter(time) do
    Timex.Date.end_of_quarter(time)
  end

  def from_epoch(options) do
    Timex.Date.set(Timex.Date.epoch, options)
  end

  def parse(input_date_time, format) do
    {:ok, result} = input_date_time |> Timex.DateFormat.parse(format, :strftime)
    result |> Timex.Timezone.convert("UTC")
  end

  def format(input_date_time, date_format) do
    {:ok, result} = input_date_time |> Timex.Timezone.convert(@time_zone_name) |> Timex.DateFormat.format(date_format, :strftime)
    result
  end
end
