defmodule RecruitxBackend.RoleSkillSpec do
  use ESpec.Phoenix, model: RecruitxBackend.RoleSkill

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.RoleSkill
  alias RecruitxBackend.Skill

  let :role, do: create(:role)
  let :skill, do: create(:skill)

  let :valid_attrs, do: fields_for(:role_skill, role_id: role.id, skill_id: skill.id)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: RoleSkill.changeset(%RoleSkill{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: RoleSkill.changeset(%RoleSkill{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([role_id: "can't be blank", skill_id: "can't be blank"])

    it "when role id is nil" do
      role_skill_with_role_id_nil = Map.merge(valid_attrs, %{role_id: nil})

      result = RoleSkill.changeset(%RoleSkill{}, role_skill_with_role_id_nil)

      expect(result) |> to(have_errors(role_id: "can't be blank"))
    end

    it "when skill id is nil" do
      role_skill_with_skill_id_nil = Map.merge(valid_attrs, %{skill_id: nil})

      result = RoleSkill.changeset(%RoleSkill{}, role_skill_with_skill_id_nil)

      expect(result) |> to(have_errors(skill_id: "can't be blank"))
    end

    it "when role id is not present" do
      role_skill_with_no_role_id = Map.delete(valid_attrs, :role_id)

      result = RoleSkill.changeset(%RoleSkill{}, role_skill_with_no_role_id)

      expect(result) |> to(have_errors(role_id: "can't be blank"))
    end

    it "when skill id is not present" do
      role_skill_with_no_skill_id = Map.delete(valid_attrs, :skill_id)

      result = RoleSkill.changeset(%RoleSkill{}, role_skill_with_no_skill_id)

      expect(result) |> to(have_errors(skill_id: "can't be blank"))
    end
  end

  context "foreign key constraint" do
    it "when role id not present in roles table" do
      current_role_count = Ectoo.count(Repo, Role)
      role_id_not_present = current_role_count + 1
      role_skill_with_invalid_role_id = Map.merge(valid_attrs, %{role_id: role_id_not_present})

      changeset = RoleSkill.changeset(%RoleSkill{}, role_skill_with_invalid_role_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([role: "does not exist"]))
    end

    it "when skill id not present in skills table" do
      current_skill_count = Ectoo.count(Repo, Skill)
      skill_id_not_present = current_skill_count + 1
      role_skill_with_invalid_skill_id = Map.merge(valid_attrs, %{skill_id: skill_id_not_present})

      changeset = RoleSkill.changeset(%RoleSkill{}, role_skill_with_invalid_skill_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([skill: "does not exist"]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same skil is added more than once for a candidate" do
      changeset = RoleSkill.changeset(%RoleSkill{}, valid_attrs)
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([role_skill: "has already been taken"]))
    end
  end
end
