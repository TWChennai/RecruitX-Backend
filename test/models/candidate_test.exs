defmodule RecruitxBackend.CandidateTest do
    use RecruitxBackend.ModelCase

    alias RecruitxBackend.Candidate

    @valid_attrs %{name: "some content"}
    @invalid_attrs %{}
    @candidate_with_empty_name %{name: ""}

    test "changeset with valid attributes" do
        changeset = Candidate.changeset(%Candidate{}, @valid_attrs)
        assert changeset.valid?
    end

    test "changeset with invalid attributes" do
        changeset = Candidate.changeset(%Candidate{}, @invalid_attrs)
        refute changeset.valid?
        # TODO: What about verifying the error messages?
    end

    test "changeset should be invalid when candidate name is empty" do
        changeset = Candidate.changeset(%Candidate{}, @candidate_with_empty_name)
        refute changeset.valid?
        # TODO: What about verifying the error messages?
    end
end
