defmodule RecruitxBackend.ChangesetErrorParserSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ChangesetErrorParser

  alias RecruitxBackend.ChangesetErrorParser

  context "to_json" do
    it "when errors is in the form of string in a single changeset" do
      [result] = ChangesetErrorParser.to_json(%{errors: [test: "is invalid"]})

      expect(result.field_name) |> to(eql(:test))
      expect(result.reason) |> to(eql("is invalid"))
    end

    it "when there are multiple errors in a single changeset" do
      [result1,result2] = ChangesetErrorParser.to_json(%{errors: [error1: "is invalid", error2: "is also invalid"]})

      expect(result1.field_name) |> to(eql(:error1))
      expect(result1.reason) |> to(eql("is invalid"))
      expect(result2.field_name) |> to(eql(:error2))
      expect(result2.reason) |> to(eql("is also invalid"))
    end

    it "when errors is in the form of tuple in a single changeset" do
      [result] = ChangesetErrorParser.to_json(%{errors: [test: {"value1", "value2"}]})

      expect(result.field_name) |> to(eql(:test))
      expect(result.reason) |> to(eql("value1"))
    end

    it "when there are no errors" do
      result = ChangesetErrorParser.to_json(%{})

      expect(result) |> to(eql([]))
    end

    it "when there are multiple changesets with errors" do
      changesets_with_errors =[%{errors: [error1: "is invalid"]}, %{errors: [error2: "is also invalid"]}]
      [result1, result2] = ChangesetErrorParser.to_json(changesets_with_errors)

      expect(result1.field_name) |> to(eql(:error1))
      expect(result1.reason) |> to(eql("is invalid"))
      expect(result2.field_name) |> to(eql(:error2))
      expect(result2.reason) |> to(eql("is also invalid"))
    end

    it "when there are multiple changesets with multiple errors" do
      changesets_with_errors =[%{errors: [error1: "is invalid"]}, %{errors: [error2: "is also invalid", error3: "is too invalid"]}]
      [result1, result2, result3] = ChangesetErrorParser.to_json(changesets_with_errors)

      expect(result1.field_name) |> to(eql(:error1))
      expect(result1.reason) |> to(eql("is invalid"))
      expect(result2.field_name) |> to(eql(:error2))
      expect(result2.reason) |> to(eql("is also invalid"))
      expect(result3.field_name) |> to(eql(:error3))
      expect(result3.reason) |> to(eql("is too invalid"))
    end

    it "when there are multiple changesets with and without errors" do
      changesets_with_errors =[%{errors: [error1: "is invalid"]}, %{changeset_without_errors: "dummy"}]
      [result1] = ChangesetErrorParser.to_json(changesets_with_errors)

      expect(result1.field_name) |> to(eql(:error1))
      expect(result1.reason) |> to(eql("is invalid"))
    end
  end
end
