defmodule RecruitxBackend.SkillTest do
  use RecruitxBackend.ModelCase

  alias RecruitxBackend.Skill

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Skill.changeset(%Skill{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Skill.changeset(%Skill{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset should be invalid when name is nil" do
    changeset = Skill.changeset(%Skill{}, %{name: nil})
    refute changeset.valid?
  end

  test "changeset should be invalid when name is empty" do
    changeset = Skill.changeset(%Skill{}, %{name: ""})
    refute changeset.valid?
  end

  test "changeset should be invalid when name is already present" do
    %Skill{}
      |> Skill.changeset(@valid_attrs)
      |> Repo.insert!
    already_present_skill = Skill.changeset(%Skill{}, @valid_attrs)

    assert {:error, changeset} = Repo.insert(already_present_skill)
    assert changeset.errors[:name] == "has already been taken"
  end

  test "getByName should return a query to get skill based on its name" do
    valid_skill = Skill.changeset( %Skill{}, @valid_attrs)
    Repo.insert!(valid_skill)

    assert [skill_queried] = Repo.all(Skill.getByName(@valid_attrs.name))
    assert skill_queried.name == @valid_attrs.name
  end

  test "getByName should return empty when queried based on non-existent skill" do
      assert [] = Repo.all(Skill.getByName("non-existent-skill"))
  end
end
