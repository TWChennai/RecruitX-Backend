defmodule RecruitxBackend.CandidateTest do
    use RecruitxBackend.ModelCase

    alias RecruitxBackend.Candidate

    @valid_attrs %{name: "some content"}
    @invalid_attrs %{}
    @candidate_with_empty_name %{name: ""}

    setup do
        Mix.Tasks.Ecto.Migrate.run(["--all", "Candidate.Repo"])

        on_exit fn ->
            Mix.Tasks.Ecto.Rollback.run(["--all", "Candidate.Repo"])
        end
    end

    test "changeset with valid attributes" do
        changeset = Candidate.changeset(%Candidate{}, @valid_attrs)
        assert changeset.valid?
    end

    test "changeset with invalid attributes" do
        changeset = Candidate.changeset(%Candidate{}, @invalid_attrs)
        refute changeset.valid?
    end

    test "changeset should be invalid when candidate name is empty" do
        changeset = Candidate.changeset(%Candidate{},@candidate_with_empty_name)
        refute changeset.valid?
    end

    test "should retrieve all candidates from the database" do
        candidate = %{"name" => "test"}
        Candidate.insert(candidate)
        candidates = Candidate.all
        assert candidates == Candidate.to_json([candidate])
    end
end
