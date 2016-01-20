defmodule RecruitxBackend.JSONErrorReasonSpec do
  use ESpec.Phoenix, model: RecruitxBackend.JSONErrorReason

  alias RecruitxBackend.JSONErrorReason

  context "json encoding" do
    it "when there is an error" do
      jsonError = %JSONErrorReason{field_name: "testField", reason: "test reason"}
      expect(Poison.encode!(jsonError, keys: :atoms!)) |> to(eq("{\"reason\":\"test reason\",\"field_name\":\"testField\"}"))
    end
  end
end
