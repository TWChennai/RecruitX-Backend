defmodule RecruitxBackend.InterviewTypeSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewType

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Interview

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
      valid_interview = InterviewType.changeset(%InterviewType{}, %{name: new_interview_type.name})
      {:error, changeset} = Repo.insert(valid_interview)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end

    it "should be invalid when interview already exists with same name but different case" do
      new_interview_type = create(:interview_type)
      valid_interview = InterviewType.changeset(%InterviewType{}, %{name: String.upcase(new_interview_type.name)})
      {:error, changeset} = Repo.insert(interview_in_caps)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end
  end

  context "on delete" do
    it "should raise an exception when it has foreign key references in other tables" do
      interview_type = create(:interview_type)
      create(:interview, interview_type_id: interview_type.id, interview_type: interview_type)

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
end
