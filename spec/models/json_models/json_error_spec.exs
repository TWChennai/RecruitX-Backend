defmodule RecruitxBackend.JSONErrorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.JSONError

  alias RecruitxBackend.JSONError
  context "json encoding" do
    it "when there are multiple errors" do
      error = %JSONError{errors: [%{test1: "test1"}, %{test2: "test2"}]}
      expect(Poison.encode!(error, keys: :atoms!)) |> to(eq("{\"errors\":[{\"test1\":\"test1\"},{\"test2\":\"test2\"}]}"))
    end

    it "when there are no errors" do
      error = %JSONError{errors: []}
      expect(Poison.encode!(error, keys: :atoms!)) |> to(eq("{\"errors\":[]}"))
    end
  end
end
