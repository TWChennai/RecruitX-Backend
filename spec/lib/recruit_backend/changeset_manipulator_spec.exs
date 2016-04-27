defmodule RecruitxBackend.ChangesetManipulatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ChangesetManipulator

  alias RecruitxBackend.ChangesetManipulator;
  alias RecruitxBackend.JSONErrorReason;
  alias RecruitxBackend.Role;
  alias RecruitxBackend.Candidate;

  context "insert" do
    it "should insert a changeset into db" do
      role = fields_for(:role)
      changesets = [Role.changeset(%Role{}, role)]
      {status, result} = changesets |> ChangesetManipulator.validate_and(Repo.custom_insert)

      expect(status) |> to(eql(:ok))
      expect(result.name) |> to(eql(role.name))
    end

    it "should not insert a changeset into db when there are changeset errors" do
      expectedRoleErrorReason = %JSONErrorReason{field_name: :name, reason: "can't be blank"}
      changesets = [Role.changeset(%Role{}, %{name: nil})]
      insert = fn -> changesets |> ChangesetManipulator.validate_and(Repo.custom_insert) end
      expected_error_to_be_thrown = {:changeset_error, [expectedRoleErrorReason]}

      expect insert |> to(throw_term expected_error_to_be_thrown)
    end

    it "should not insert a changeset into db when there are constraint errors on db insertion" do
      expectedRoleErrorReason = %JSONErrorReason{field_name: :role, reason: "does not exist"}
      candidate = fields_for(:candidate)
      changesets = [Candidate.changeset(%Candidate{}, Map.merge(candidate, %{role_id: -1}))]
      insert = fn -> changesets |> ChangesetManipulator.validate_and(Repo.custom_insert) end
      expected_error_to_be_thrown = {:error, [expectedRoleErrorReason]}

      expect insert |> to(throw_term expected_error_to_be_thrown)
    end
  end

  context "update" do
    it "should update changeset into db" do
      role = create(:role)
      changesets = [Role.changeset(role, %{"name": "test"})]
      {status, result} = changesets |> ChangesetManipulator.validate_and(Repo.custom_update)

      expect(status) |> to(eql(:ok))
      expect(result.name) |> to(eql("test"))
    end

    it "should not update a changeset into db when there are changeset errors" do
      expectedRoleErrorReason = %JSONErrorReason{field_name: :name, reason: "can't be blank"}
      role = create(:role)
      changesets = [Role.changeset(role, %{"name": nil})]
      update = fn -> changesets |> ChangesetManipulator.validate_and(Repo.custom_update) end
      expected_error_to_be_thrown = {:changeset_error, [expectedRoleErrorReason]}

      expect update |> to(throw_term expected_error_to_be_thrown)
    end

    it "should not update a changeset into db when there are constraint errors on db insertion" do
      expectedRoleErrorReason = %JSONErrorReason{field_name: :role, reason: "does not exist"}
      candidate = create(:candidate)
      changesets = [Candidate.changeset(candidate, %{role_id: -1})]
      update = fn -> changesets |> ChangesetManipulator.validate_and(Repo.custom_update) end
      expected_error_to_be_thrown = {:error, [expectedRoleErrorReason]}

      expect update |> to(throw_term expected_error_to_be_thrown)
    end
  end

  def get_candidate_count do
    Ectoo.count(Repo, Candidate)
  end
end
