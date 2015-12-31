defmodule RecruitxBackend.CandidateTest do
    use RecruitxBackend.ModelCase

    alias RecruitxBackend.Candidate
    alias RecruitxBackend.Role

    @role Repo.insert!(%Role{name: "test_role"})
    @valid_attrs %{name: "some content", experience: Decimal.new(3.3), role_id: @role.id, additional_information: "info"}
    @invalid_attrs %{}

    test "changeset with valid attributes" do
        changeset = Candidate.changeset(%Candidate{}, @valid_attrs)
        assert changeset.valid?
    end

    test "changeset with invalid attributes" do
        changeset = Candidate.changeset(%Candidate{}, @invalid_attrs)
        refute changeset.valid?

        assert {:name, "can't be blank"} in changeset.errors
        assert {:role_id, "can't be blank"} in changeset.errors
        assert {:experience, "can't be blank"} in changeset.errors
    end

    test "changeset should be invalid when candidate name is empty" do
        candidate_with_empty_name = Dict.merge(@valid_attrs, %{name: ""})
        changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

        refute changeset.valid?
        assert {:name, {"should be at least %{count} character(s)", [count: 1]}} in changeset.errors
    end

    # TODO: Verifying when candidate name is blank

    test "changeset should be invalid when experience is nil" do
        candidate_with_nil_experience = Dict.merge(@valid_attrs, %{experience: nil})
        changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_experience)

        refute changeset.valid?
        assert {:experience, "can't be blank"} in changeset.errors
    end

    test "changeset should be invalid when experience is an empty string" do
        candidate_with_empty_experience = Dict.merge(@valid_attrs, %{experience: ""})
        changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_experience)

        refute changeset.valid?
        assert {:experience, "is invalid"} in changeset.errors
    end

    test "changeset should be invalid when no experience is given" do
        candidate_with_no_experience = Dict.delete(@valid_attrs, :experience)
        changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

        refute changeset.valid?
        assert {:experience, "can't be blank"} in changeset.errors
    end

    test "changeset should be valid when additional information is not given" do
        candidate_with_no_additional_information = Dict.delete(@valid_attrs, :additional_information)
        changeset = Candidate.changeset(%Candidate{}, candidate_with_no_additional_information)

        assert changeset.valid?
    end

end
