defmodule RecruitxBackend.JSONErrorReason do
  @derive {Poison.Encoder, only: [:field_name, :reason]}
  defstruct field_name: "", reason: ""
end
