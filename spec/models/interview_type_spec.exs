defmodule RecruitxBackend.InterviewTypeSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewType

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Slot

  let :valid_attrs, do: params_with_assocs(:interview_type, priority: Enum.random(1..10))
  let :invalid_attrs, do: %{}

  context "interview type spec" do
    before do: Enum.each([Interview, Slot, InterviewType], &Repo.delete_all/1)

    context "valid changeset" do
      subject do: InterviewType.changeset(%InterviewType{}, valid_attrs())

      it do: should be_valid()

      it "should be valid when name has numbers in it" do
        interview_with_numbers = Map.merge(valid_attrs(), %{name: "P3"})
        changeset = InterviewType.changeset(%InterviewType{}, interview_with_numbers)

        expect(changeset) |> to(be_valid())
      end

      it "should be valid when no priority is given" do
        interview_with_no_priority = Map.delete(valid_attrs(), :priority)
        changeset = InterviewType.changeset(%InterviewType{}, interview_with_no_priority)

        expect(changeset) |> to(be_valid())
      end
    end

    context "invalid changeset" do
      subject do: InterviewType.changeset(%InterviewType{}, invalid_attrs())

      it do: should_not be_valid()
      it do: should have_errors(name: {"can't be blank", [validation: :required]})

      it "should be invalid when name is an empty string" do
        interview_with_empty_name = Map.merge(valid_attrs(), %{name: ""})
        changeset = InterviewType.changeset(%InterviewType{}, interview_with_empty_name)

        expect(changeset) |> to(have_errors(name: {"can't be blank", [validation: :required]}))
      end

      it "should be invalid when name is a blank string" do
        interview_with_blank_name = Map.merge(valid_attrs(), %{name: "  "})
        changeset = InterviewType.changeset(%InterviewType{}, interview_with_blank_name)

        expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
      end

      it "should be invalid when name is only numbers" do
        interview_with_numbers_name = Map.merge(valid_attrs(), %{name: "678"})
        changeset = InterviewType.changeset(%InterviewType{}, interview_with_numbers_name)

        expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
      end

      it "should be invalid when name begins with numbers" do
        interview_beginning_with_numbers_name = Map.merge(valid_attrs(), %{name: "678AB"})
        changeset = InterviewType.changeset(%InterviewType{}, interview_beginning_with_numbers_name)

        expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
      end

      it "should be invalid when name starts with space" do
        interview_starting_with_space_name = Map.merge(valid_attrs(), %{name: " space"})
        changeset = InterviewType.changeset(%InterviewType{}, interview_starting_with_space_name)

        expect(changeset) |> to(have_errors([name: {"has invalid format", [validation: :format]}]))
      end
    end

    context "unique_constraint" do
      it "should be invalid when interview already exists with same name" do
        new_interview_type = insert(:interview_type)
        valid_interview = InterviewType.changeset(%InterviewType{}, params_with_assocs(:interview_type, name: new_interview_type.name))
        {:error, changeset} = Repo.insert(valid_interview)
        expect(changeset) |> to(have_errors(name: {"has already been taken", []}))
      end

      it "should be invalid when interview already exists with same name but different case" do
        new_interview_type = insert(:interview_type)
        valid_interview = InterviewType.changeset(%InterviewType{}, params_with_assocs(:interview_type, name: String.upcase(new_interview_type.name)))
        {:error, changeset} = Repo.insert(valid_interview)
        expect(changeset) |> to(have_errors(name: {"has already been taken", []}))
      end
    end

    context "on delete" do
      it "should raise an exception when it has foreign key references in other tables" do
        interview_type = insert(:interview_type)
        insert(:interview, interview_type: interview_type)

        delete = fn ->  Repo.delete!(interview_type) end

        expect(delete).to raise_exception(Ecto.ConstraintError)
      end

      it "should not raise an exception when it has no foreign key references in other tables" do
        interview = insert(:interview_type)

        delete = fn -> Repo.delete!(interview) end

        expect(delete).to_not raise_exception(Ecto.ConstraintError)
      end
    end

    context "default_order" do
      it "should sort by ascending order of priority" do
        interview_with_priority_2 = insert(:interview_type, priority: 2)
        interview_with_priority_1 = insert(:interview_type, priority: 1)
        interview_with_priority_3 = insert(:interview_type, priority: 3)

        interviews = InterviewType |> InterviewType.default_order |> Repo.all

        expect(interviews) |> to(eq([interview_with_priority_1, interview_with_priority_2, interview_with_priority_3]))
      end

      it "should tie-break on id for the same priority" do
        interview_with_priority_2_id_1 = insert(:interview_type, priority: 2)
        interview_with_priority_2_id_2 = insert(:interview_type, priority: 2)
        interview_with_priority_1 = insert(:interview_type, priority: 1)

        interviews = InterviewType |> InterviewType.default_order |> Repo.all

        expect(interviews) |> to(eq([interview_with_priority_1, interview_with_priority_2_id_1, interview_with_priority_2_id_2]))
      end
    end

    context "retrieve_by_name" do
      it "should give interview_type if present by that name" do
        interview_type_test = insert(:interview_type, name: "test")

        interview_type = InterviewType.retrieve_by_name("test")

        expect(interview_type.id) |> to(eq(interview_type_test.id))
      end

      it "should not give interview_type if not present by that name" do
        interview_type = InterviewType.retrieve_by_name("test")

        expect(interview_type) |> to(be_nil())
      end
    end

    context "get_sign_up_limits" do
      it "should give the maximum sign up limit for all interview rounds" do
        interview_type_1 = insert(:interview_type)
        interview_type_2 = insert(:interview_type)

        [result1, result2] = InterviewType.get_sign_up_limits

        expect result1 |> to(be({interview_type_1.id, interview_type_1.max_sign_up_limit}))
        expect result2 |> to(be({interview_type_2.id, interview_type_2.max_sign_up_limit}))
      end

      it "should give an empty result set when no entries are present" do
        expect InterviewType.get_sign_up_limits |> to(be([]))
      end
    end
  end
end
