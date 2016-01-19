defmodule RecruitxBackend.JSONError do
  @derive {Poison.Encoder, only: [ :errors]}
  defstruct errors: ""
end
