defmodule RecruitxBackend.SkillSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Skill

  alias RecruitxBackend.Skill

  let :valid_attrs, do: %{name: "some content"}
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Skill.changeset(%Skill{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: Skill.changeset(%Skill{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank")

    it "should be invalid when name is an empty string" do
      skill_with_empty_name = Dict.merge(valid_attrs, %{name: ""})
      changeset = Skill.changeset(%Skill{}, skill_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is a blank string"
  end

  context "unique_constraint" do
    it "should be invalid when skill already exists with same name" do
      valid_skill = Skill.changeset(%Skill{}, valid_attrs)
      Repo.insert!(valid_skill)

      {:error, changeset} = Repo.insert(valid_skill)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end
  end
end
