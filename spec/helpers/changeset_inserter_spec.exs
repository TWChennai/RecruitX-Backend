defmodule RecruitxBackend.ChangesetInserterSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ChangesetInserter

  alias RecruitxBackend.ChangesetInserter;
  alias RecruitxBackend.JSONErrorReason;
  alias RecruitxBackend.Role;
  alias RecruitxBackend.Candidate;

  context "getChangesetErrorsInReadableFormat" do
    it "when errors is in the form of string" do
      [result] = ChangesetInserter.getChangesetErrorsInReadableFormat(%{errors: [test: "is invalid"]})

      expect(result.field_name) |> to(eql(:test))
      expect(result.reason) |> to(eql("is invalid"))
    end

    it "when there are multiple errors" do
      [result1,result2] = ChangesetInserter.getChangesetErrorsInReadableFormat(%{errors: [error1: "is invalid", error2: "is also invalid"]})

      expect(result1.field_name) |> to(eql(:error1))
      expect(result1.reason) |> to(eql("is invalid"))
      expect(result2.field_name) |> to(eql(:error2))
      expect(result2.reason) |> to(eql("is also invalid"))
    end

    it "when errors is in the form of tuple" do
      [result] = ChangesetInserter.getChangesetErrorsInReadableFormat(%{errors: [test: {"value1", "value2"}]})

      expect(result.field_name) |> to(eql(:test))
      expect(result.reason) |> to(eql("value1"))
    end

    it "when there are no errors" do
      result = ChangesetInserter.getChangesetErrorsInReadableFormat(%{})

      expect(result) |> to(eql([]))
    end
  end

  context "insertChangesets" do
    it "should insert a changeset into db" do
      role = fields_for(:role)
      changesets = [Role.changeset(%Role{}, role)]
      {status, result} = ChangesetInserter.insertChangesets(changesets)

      expect(status) |> to(eql(:ok))
      expect(result.name) |> to(eql(role.name))
    end

    it "should not insert a changeset into db when there are changeset errors" do
      expectedRoleErrorReason = %JSONErrorReason{field_name: :name, reason: "can't be blank"}
      changesets = [Role.changeset(%Role{}, %{name: nil})]
      insert = fn -> ChangesetInserter.insertChangesets(changesets) end
      expected_error_to_be_thrown = {:changeset_error, [expectedRoleErrorReason]}

      expect insert |> to(throw_term expected_error_to_be_thrown)
    end

    it "should not insert a changeset into db when there are constraint errors on db insertion" do
      expectedRoleErrorReason = %JSONErrorReason{field_name: :role, reason: "does not exist"}
      candidate = fields_for(:candidate)
      changesets = [Candidate.changeset(%Candidate{}, Map.merge(candidate, %{role_id: -1}))]
      insert = fn -> ChangesetInserter.insertChangesets(changesets) end
      expected_error_to_be_thrown = {:error, [expectedRoleErrorReason]}

      expect insert |> to(throw_term expected_error_to_be_thrown)
    end
  end

  def get_candidate_count do
    Ectoo.count(Repo, Candidate)
  end

end
