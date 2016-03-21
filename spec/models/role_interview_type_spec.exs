defmodule RecruitxBackend.RoleInterviewTypeSpec do
  use ESpec.Phoenix, model: RecruitxBackend.RoleInterviewType

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.RoleInterviewType
  alias RecruitxBackend.InterviewType

  let :role, do: create(:role)
  let :interview_type, do: create(:interview_type)

  let :valid_attrs, do: fields_for(:role_interview_type, role_id: role.id, interview_type_id: interview_type.id)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: RoleInterviewType.changeset(%RoleInterviewType{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: RoleInterviewType.changeset(%RoleInterviewType{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([role_id: "can't be blank", interview_type_id: "can't be blank"])

    it "when role id is nil" do
      role_interview_type_with_role_id_nil = Map.merge(valid_attrs, %{role_id: nil})

      result = RoleInterviewType.changeset(%RoleInterviewType{}, role_interview_type_with_role_id_nil)

      expect(result) |> to(have_errors(role_id: "can't be blank"))
    end

    it "when interview_type id is nil" do
      role_interview_type_with_interview_type_id_nil = Map.merge(valid_attrs, %{interview_type_id: nil})

      result = RoleInterviewType.changeset(%RoleInterviewType{}, role_interview_type_with_interview_type_id_nil)

      expect(result) |> to(have_errors(interview_type_id: "can't be blank"))
    end

    it "when role id is not present" do
      role_interview_type_with_no_role_id = Map.delete(valid_attrs, :role_id)

      result = RoleInterviewType.changeset(%RoleInterviewType{}, role_interview_type_with_no_role_id)

      expect(result) |> to(have_errors(role_id: "can't be blank"))
    end

    it "when interview_type id is not present" do
      role_interview_type_with_no_interview_type_id = Map.delete(valid_attrs, :interview_type_id)

      result = RoleInterviewType.changeset(%RoleInterviewType{}, role_interview_type_with_no_interview_type_id)

      expect(result) |> to(have_errors(interview_type_id: "can't be blank"))
    end
  end

  context "foreign key constraint" do
    it "when role id not present in roles table" do
      current_role_count = Ectoo.count(Repo, Role)
      role_id_not_present = current_role_count + 1
      role_interview_type_with_invalid_role_id = Map.merge(valid_attrs, %{role_id: role_id_not_present})

      changeset = RoleInterviewType.changeset(%RoleInterviewType{}, role_interview_type_with_invalid_role_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([role: "does not exist"]))
    end

    it "when interview_type id not present in interview_types table" do
      current_interview_type_count = Ectoo.count(Repo, InterviewType)
      interview_type_id_not_present = current_interview_type_count + 1
      role_interview_type_with_invalid_interview_type_id = Map.merge(valid_attrs, %{interview_type_id: interview_type_id_not_present})

      changeset = RoleInterviewType.changeset(%RoleInterviewType{}, role_interview_type_with_invalid_interview_type_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_type: "does not exist"]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same interview_type is added more than once for a role" do
      changeset = RoleInterviewType.changeset(%RoleInterviewType{}, valid_attrs)
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([role_interview_type: "has already been taken"]))
    end
  end
end
