defmodule RecruitxBackend.InterviewTypeSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewType

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.RoleInterviewType
  alias RecruitxBackend.Repo

  let :valid_attrs, do: fields_for(:interview_type, priority: trunc(:rand.uniform * 10))
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: InterviewType.changeset(%InterviewType{}, valid_attrs)

    it do: should be_valid

    it "should be valid when name has numbers in it" do
      interview_with_numbers = Map.merge(valid_attrs, %{name: "P3"})
      changeset = InterviewType.changeset(%InterviewType{}, interview_with_numbers)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when no priority is given" do
      interview_with_no_priority = Map.delete(valid_attrs, :priority)
      changeset = InterviewType.changeset(%InterviewType{}, interview_with_no_priority)

      expect(changeset) |> to(be_valid)
    end
  end

  context "invalid changeset" do
    subject do: InterviewType.changeset(%InterviewType{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank")

    it "should be invalid when name is an empty string" do
      interview_with_empty_name = Map.merge(valid_attrs, %{name: ""})
      changeset = InterviewType.changeset(%InterviewType{}, interview_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is a blank string" do
      interview_with_blank_name = Map.merge(valid_attrs, %{name: "  "})
      changeset = InterviewType.changeset(%InterviewType{}, interview_with_blank_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name is only numbers" do
      interview_with_numbers_name = Map.merge(valid_attrs, %{name: "678"})
      changeset = InterviewType.changeset(%InterviewType{}, interview_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name begins with numbers" do
      interview_beginning_with_numbers_name = Map.merge(valid_attrs, %{name: "678AB"})
      changeset = InterviewType.changeset(%InterviewType{}, interview_beginning_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name starts with space" do
      interview_starting_with_space_name = Map.merge(valid_attrs, %{name: " space"})
      changeset = InterviewType.changeset(%InterviewType{}, interview_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end
  end

  context "unique_constraint" do
    it "should be invalid when interview already exists with same name" do
      new_interview_type = create(:interview_type)
      valid_interview = InterviewType.changeset(%InterviewType{}, fields_for(:interview_type, name: new_interview_type.name))
      {:error, changeset} = Repo.insert(valid_interview)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end

    it "should be invalid when interview already exists with same name but different case" do
      new_interview_type = create(:interview_type)
      valid_interview = InterviewType.changeset(%InterviewType{}, fields_for(:interview_type, name: String.upcase(new_interview_type.name)))
      {:error, changeset} = Repo.insert(valid_interview)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end
  end

  context "on delete" do
    it "should raise an exception when it has foreign key references in other tables" do
      interview_type = create(:interview_type)
      create(:interview, interview_type_id: interview_type.id)

      delete = fn ->  Repo.delete!(interview_type) end

      expect(delete).to raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      interview = create(:interview_type)

      delete = fn -> Repo.delete!(interview) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end

  context "default_order" do
    before do: Repo.delete_all(Interview)
    before do: Repo.delete_all(InterviewType)

    it "should sort by ascending order of priority" do
      interview_with_priority_2 = create(:interview_type, priority: 2)
      interview_with_priority_1 = create(:interview_type, priority: 1)
      interview_with_priority_3 = create(:interview_type, priority: 3)

      interviews = InterviewType |> InterviewType.default_order |> Repo.all

      expect(interviews) |> to(eq([interview_with_priority_1, interview_with_priority_2, interview_with_priority_3]))
    end

    it "should tie-break on id for the same priority" do
      interview_with_priority_2_id_1 = create(:interview_type, priority: 2)
      interview_with_priority_2_id_2 = create(:interview_type, priority: 2)
      interview_with_priority_1 = create(:interview_type, priority: 1)

      interviews = InterviewType |> InterviewType.default_order |> Repo.all

      expect(interviews) |> to(eq([interview_with_priority_1, interview_with_priority_2_id_1, interview_with_priority_2_id_2]))
    end
  end

  context "get_ids_of_min_priority_round" do
    before do: Repo.delete_all(Interview)
    before do: Repo.delete_all(InterviewType)

    it "should give interview_type with minimum priority" do
      Repo.delete_all InterviewType
      role = create(:role)
      interview_with_priority_1 = create(:interview_type, priority: 1)
      interview_with_priority_2 = create(:interview_type, priority: 2)
      create(:interview_type, priority: 3)
      Repo.insert(RoleInterviewType.changeset(%RoleInterviewType{}, %{interview_type_id: interview_with_priority_1.id, role_id: role.id, optional: false}))
      Repo.insert(RoleInterviewType.changeset(%RoleInterviewType{}, %{interview_type_id: interview_with_priority_2.id, role_id: role.id, optional: false}))

      [minimum_interview_id] = InterviewType.get_ids_of_min_priority_round

      expect(minimum_interview_id) |> to(eq(interview_with_priority_1.id))
    end

    it "should give interview_type with minimum priority and not optional" do
      Repo.delete_all InterviewType
      role = create(:role)
      interview_with_priority_1 = create(:interview_type, priority: 1)
      interview_with_priority_2 = create(:interview_type, priority: 2)
      create(:interview_type, priority: 3)
      Repo.insert(RoleInterviewType.changeset(%RoleInterviewType{}, %{interview_type_id: interview_with_priority_1.id, role_id: role.id, optional: true}))
      Repo.insert(RoleInterviewType.changeset(%RoleInterviewType{}, %{interview_type_id: interview_with_priority_2.id, role_id: role.id, optional: false}))

      [minimum_interview_id] = InterviewType.get_ids_of_min_priority_round

      expect(minimum_interview_id) |> to(eq(interview_with_priority_2.id))
    end

    it "should give interview_types with minimum priority when there are multiple interviews" do
      Repo.delete_all InterviewType
      role = create(:role)
      interview1_with_priority_1 = create(:interview_type, priority: 1)
      interview2_with_priority_1 = create(:interview_type, priority: 1)
      create(:interview_type, priority: 2)
      create(:interview_type, priority: 3)
      Repo.insert(RoleInterviewType.changeset(%RoleInterviewType{}, %{interview_type_id: interview1_with_priority_1.id, role_id: role.id, optional: false}))
      Repo.insert(RoleInterviewType.changeset(%RoleInterviewType{}, %{interview_type_id: interview2_with_priority_1.id, role_id: role.id, optional: false}))

      [minimum_interview_id1, minimum_interview_id2] = InterviewType.get_ids_of_min_priority_round

      expect(minimum_interview_id1) |> to(eq(interview1_with_priority_1.id))
      expect(minimum_interview_id2) |> to(eq(interview2_with_priority_1.id))
    end
  end

  context "retrieve_by_name" do
    it "should give interview_type if present by that name" do
      interview_type_test = create(:interview_type, name: "test")

      interview_type = InterviewType.retrieve_by_name("test")

      expect(interview_type.id) |> to(eq(interview_type_test.id))
    end

    it "should not give interview_type if not present by that name" do
      Repo.delete_all(Interview)
      Repo.delete_all(InterviewType)

      interview_type = InterviewType.retrieve_by_name("test")

      expect(interview_type) |> to(be_nil)
    end
  end

  context "get_sign_up_limits" do
    it "should give the maximum sign up limit for all interview rounds" do
      Repo.delete_all(Interview)
      Repo.delete_all(InterviewType)

      interview_type_1 = create(:interview_type)
      interview_type_2 = create(:interview_type)

      [result1, result2] = InterviewType.get_sign_up_limits

      expect result1 |> to(be({interview_type_1.id, interview_type_1.max_sign_up_limit}))
      expect result2 |> to(be({interview_type_2.id, interview_type_2.max_sign_up_limit}))
    end

    it "should give an empty result set when no entries are present" do
      Repo.delete_all(Interview)
      Repo.delete_all(InterviewType)

      expect InterviewType.get_sign_up_limits |> to(be([]))
    end
  end
end
