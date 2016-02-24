defmodule RecruitxBackend.AppConstants do
  @name_format ~r/^[a-z]+[\sa-z]*$/i

  def name_format, do: @name_format
end
