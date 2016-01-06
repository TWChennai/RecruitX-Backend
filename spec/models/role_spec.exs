defmodule RecruitxBackend.RoleSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Role

  alias RecruitxBackend.Role

  let :valid_attrs, do: %{name: "some content"}
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
      role_with_empty_name = Dict.merge(valid_attrs, %{name: ""})
      changeset = Role.changeset(%Role{}, role_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is nil" do
      role_with_nil_name = Dict.merge(valid_attrs, %{name: nil})
      changeset = Role.changeset(%Role{}, role_with_nil_name)

      expect(changeset) |> to(have_errors([name: "can't be blank"]))
    end

    it "should be invalid when name is a blank string" do
      role_with_blank_name = Dict.merge(valid_attrs, %{name: "  "})
      changeset = Role.changeset(%Role{}, role_with_blank_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name is only numbers" do
      role_with_numbers_name = Dict.merge(valid_attrs, %{name: "678"})
      changeset = Role.changeset(%Role{}, role_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name starts with space" do
      role_starting_with_space_name = Dict.merge(valid_attrs, %{name: " space"})
      changeset = Role.changeset(%Role{}, role_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end
  end

  context "unique_constraint" do
    it "should be invalid when role already exists with same name" do
      valid_role = Role.changeset(%Role{}, valid_attrs)
      Repo.insert!(valid_role)

      {:error, changeset} = Repo.insert(valid_role)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end

    it "should be invalid when role already exists with same name but mixed case" do
      valid_role = Role.changeset(%Role{}, valid_attrs)
      Repo.insert!(valid_role)

      valid_role_in_caps = Role.changeset(%Role{}, %{name: "Some ContenT"})

      {:error, changeset} = Repo.insert(valid_role_in_caps)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end

    it "should be invalid when role already exists with same name but upper case" do
      valid_role = Role.changeset(%Role{}, valid_attrs)
      Repo.insert!(valid_role)

      valid_role_in_caps = Role.changeset(%Role{}, %{name: String.capitalize(valid_attrs.name)})

      {:error, changeset} = Repo.insert(valid_role_in_caps)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end
  end
end
