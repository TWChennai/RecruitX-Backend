defmodule RecruitxBackend.SkillSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Skill

  alias RecruitxBackend.Skill

  let :valid_attrs, do: params_with_assocs(:skill)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Skill.changeset(%Skill{}, valid_attrs())

    it do: should be_valid()
  end

  context "invalid changeset" do
    subject do: Skill.changeset(%Skill{}, invalid_attrs())

    it do: should_not be_valid()
    it do: should have_errors(name: {"can't be blank", [validation: :required]})

    it "should be invalid when name is an empty string" do
      skill_with_empty_name = Map.merge(valid_attrs(), %{name: ""})
      changeset = Skill.changeset(%Skill{}, skill_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"can't be blank", [validation: :required]}))
    end

    it "should be invalid when name is nil" do
      skill_with_nil_name = Map.merge(valid_attrs(), %{name: nil})
      changeset = Skill.changeset(%Skill{}, skill_with_nil_name)

      expect(changeset) |> to(have_errors([name: {"can't be blank", [validation: :required]}]))
    end

    it "should be invalid when name is a blank string" do
      skill_with_blank_name = Map.merge(valid_attrs(), %{name: "  "})
      changeset = Skill.changeset(%Skill{}, skill_with_blank_name)

      expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when name is only numbers" do
      skill_with_numbers_name = Map.merge(valid_attrs(), %{name: "678"})
      changeset = Skill.changeset(%Skill{}, skill_with_numbers_name)

      expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when name starts with space" do
      skill_starting_with_space_name = Map.merge(valid_attrs(), %{name: " space"})
      changeset = Skill.changeset(%Skill{}, skill_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
    end
  end

  context "unique_constraint" do
    it "should be invalid when skill already exists with same name" do
      valid_skill = Skill.changeset(%Skill{}, valid_attrs())
      Repo.insert!(valid_skill)

      {:error, changeset} = Repo.insert(valid_skill)
      expect(changeset) |> to(have_errors(name: {"has already been taken", []}))
    end

    it "should be invalid when skill already exists with same name but different case" do
      valid_skill = Skill.changeset(%Skill{}, valid_attrs())
      Repo.insert!(valid_skill)

      skill_in_caps = Skill.changeset(%Skill{}, %{name: String.upcase(valid_attrs().name)})

      {:error, changeset} = Repo.insert(skill_in_caps)
      expect(changeset) |> to(have_errors(name: {"has already been taken", []}))
    end
  end

  context "on delete" do
    it "should raise an exception when it has foreign key references" do
      skill = insert(:skill)
      insert(:candidate_skill, skill: skill)

      delete = fn ->  Repo.delete!(skill) end

      expect(delete).to raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references" do
      skill =  Repo.insert!(%Skill{name: "test_skill"})

      delete = fn -> Repo.delete!(skill) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end
end
