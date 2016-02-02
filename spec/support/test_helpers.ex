defmodule RecruitxBackend.TestHelpers do
  def convertKeysFromAtomsToStrings(input) do
    for {key, val} <- input, into: %{}, do: {to_string(key), val}
  end
end
