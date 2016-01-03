defmodule RecruitxBackend.RoleTest do
  use RecruitxBackend.ModelCase

  alias RecruitxBackend.Role

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Role.changeset(%Role{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Role.changeset(%Role{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset should be invalid when name is nil" do
    changeset = Role.changeset(%Role{}, %{name: nil})
    refute changeset.valid?
  end

  test "changeset should be invalid when name is empty" do
    changeset = Role.changeset(%Role{}, %{name: ""})
    refute changeset.valid?
  end

  test "changeset should be invalid when name is not unique" do
    valid_role = Role.changeset(%Role{}, @valid_attrs)
    Repo.insert!(valid_role)

    assert {:error, changeset} = Repo.insert(valid_role)
    assert changeset.errors[:name] == "has already been taken"
  end
end
