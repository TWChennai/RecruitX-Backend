defmodule RecruitxBackend.InterviewStatusSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewStatus

  alias RecruitxBackend.InterviewStatus

  let :valid_attrs, do: fields_for(:interview_status)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: InterviewStatus.changeset(%InterviewStatus{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: InterviewStatus.changeset(%InterviewStatus{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank")

    it "should be invalid when name is an empty string" do
      interview_status_with_empty_name = Map.merge(valid_attrs, %{name: ""})
      changeset = InterviewStatus.changeset(%InterviewStatus{}, interview_status_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is nil" do
      interview_status_with_nil_name = Map.merge(valid_attrs, %{name: nil})
      changeset = InterviewStatus.changeset(%InterviewStatus{}, interview_status_with_nil_name)

      expect(changeset) |> to(have_errors([name: "can't be blank"]))
    end

    it "should be invalid when name is a blank string" do
      interview_status_with_blank_name = Map.merge(valid_attrs, %{name: "  "})
      changeset = InterviewStatus.changeset(%InterviewStatus{}, interview_status_with_blank_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name is only numbers" do
      interview_status_with_numbers_name = Map.merge(valid_attrs, %{name: "678"})
      changeset = InterviewStatus.changeset(%InterviewStatus{}, interview_status_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name starts with space" do
      interview_status_starting_with_space_name = Map.merge(valid_attrs, %{name: " space"})
      changeset = InterviewStatus.changeset(%InterviewStatus{}, interview_status_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end
  end

    context "unique_constraint" do
      it "should be invalid when interview_status already exists with same name" do
        valid_interview_status = create(:interview_status)

        interview_status = InterviewStatus.changeset(%InterviewStatus{}, %{name: valid_interview_status.name})

        {:error, changeset} = Repo.insert(interview_status)
        expect(changeset) |> to(have_errors(name: "has already been taken"))
      end

      it "should be invalid when interview_status already exists with same name but different case" do
        valid_interview_status = create(:interview_status)

        interview_status_in_caps = InterviewStatus.changeset(%InterviewStatus{}, %{name: String.upcase(valid_interview_status.name)})

        {:error, changeset} = Repo.insert(interview_status_in_caps)
        expect(changeset) |> to(have_errors(name: "has already been taken"))
      end
    end
end
