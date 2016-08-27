defmodule RecruitxBackend.RoleSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Role

  alias RecruitxBackend.Role

  let :valid_attrs, do: fields_for(:role)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Role.changeset(%Role{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: Role.changeset(%Role{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank")

    it "should be invalid when name is an empty string" do
      role_with_empty_name = Map.merge(valid_attrs, %{name: ""})
      changeset = Role.changeset(%Role{}, role_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is nil" do
      role_with_nil_name = Map.merge(valid_attrs, %{name: nil})
      changeset = Role.changeset(%Role{}, role_with_nil_name)

      expect(changeset) |> to(have_errors([name: "can't be blank"]))
    end

    it "should be invalid when name is a blank string" do
      role_with_blank_name = Map.merge(valid_attrs, %{name: "  "})
      changeset = Role.changeset(%Role{}, role_with_blank_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name is only numbers" do
      role_with_numbers_name = Map.merge(valid_attrs, %{name: "678"})
      changeset = Role.changeset(%Role{}, role_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name starts with space" do
      role_starting_with_space_name = Map.merge(valid_attrs, %{name: " space"})
      changeset = Role.changeset(%Role{}, role_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end
  end

  context "unique_constraint" do
    it "should be invalid when role already exists with same name" do
      new_role = create(:role)
      valid_role = Role.changeset(%Role{}, %{name: new_role.name})
      {:error, changeset} = Repo.insert(valid_role)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end

    it "should be invalid when role already exists with same name but different case" do
      new_role = create(:role)
      role_in_caps = Role.changeset(%Role{}, %{name: String.upcase(new_role.name)})
      {:error, changeset} = Repo.insert(role_in_caps)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end
  end

  context "retrieve_by_name" do
    it "should return role if it exists" do
      role = create(:role)

      result = Role.retrieve_by_name role.name

      expect(result.id) |> to(eql(result.id))
      expect(result.name) |> to(eql(result.name))
    end
  end

  context "is_ba_or_pm" do
    let :ba_and_pm_list, do: Role.ba_and_pm_list
    it "should return true if role is ba" do
      ba_role_id = Role.retrieve_by_name(Role.ba).id
      expect(Role.is_ba_or_pm(ba_role_id, ba_and_pm_list)) |> to(be(true))
    end

    it "should return true if role is pm" do
      pm_role_id = Role.retrieve_by_name(Role.pm).id
      expect(Role.is_ba_or_pm(pm_role_id, ba_and_pm_list)) |> to(be(true))
    end

    it "should return false if role is not pm or ba" do
      other_role_id = create(:role).id
      expect(Role.is_ba_or_pm(other_role_id, ba_and_pm_list)) |> to(be(false))
    end
  end
end
