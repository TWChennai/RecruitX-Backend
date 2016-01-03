defmodule RecruitxBackend.InterviewTest do
  use RecruitxBackend.ModelCase

  alias RecruitxBackend.Interview

  @valid_attrs %{name: "some content", priority: 42}
  @invalid_attrs %{}

  # TODO: Check if its possible to group tests for more meaningful groups

  test "changeset with valid attributes" do
    changeset = Interview.changeset(%Interview{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Interview.changeset(%Interview{}, @invalid_attrs)
    refute changeset.valid?
    # TODO: What about verifying the error messages?
  end

  test "changeset should be valid when name is valid and priority is empty" do
    changeset = Interview.changeset(%Interview{},%{name: "test"})
    assert changeset.valid?
  end

  test "changeset should be invalid when name is nil" do
    changeset = Interview.changeset(%Interview{}, %{name: nil})
    refute changeset.valid?
    # TODO: What about verifying the error messages?
  end

  test "changeset should be invalid when name is empty" do
    changeset = Interview.changeset(%Interview{}, %{name: ""})
    refute changeset.valid?
    # TODO: What about verifying the error messages?
  end
  # TODO: Add blank string check

  test "changeset should be invalid when interview already exists with same name" do
    valid_interview = Interview.changeset(%Interview{}, @valid_attrs)
    Repo.insert!(valid_interview)

    assert {:error, changeset} = Repo.insert(valid_interview)
    assert changeset.errors[:name] === "has already been taken"
  end
end
