defmodule RecruitxBackend.CandidateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Candidate

  alias RecruitxBackend.Candidate

  let :valid_attrs, do: fields_for(:candidate, additional_information: "info", role_id: create(:role).id)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Candidate.changeset(%Candidate{}, valid_attrs)

    it do: should be_valid

    it "should be valid when additional information is not given" do
      candidate_with_no_additional_information = Map.delete(valid_attrs, :additional_information)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_additional_information)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when experience is 0" do
      candidate_with_no_experience = Map.merge(valid_attrs, %{experience: Decimal.new(0)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(be_valid)
    end
  end

  context "invalid changeset" do
    subject do: Candidate.changeset(%Candidate{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank", role_id: "can't be blank", experience: "can't be blank")

    it "should be invalid when name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs, %{name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs, %{name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([name: "can't be blank"]))
    end

    it "should be invalid when name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs, %{name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs, %{name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs, %{name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when experience is nil" do
      candidate_with_nil_experience = Map.merge(valid_attrs, %{experience: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_experience)

      expect(changeset) |> to(have_errors(experience: "can't be blank"))
    end

    it "should be invalid when experience is an empty string" do
      candidate_with_empty_experience = Map.merge(valid_attrs, %{experience: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_experience)

      expect(changeset) |> to(have_errors(experience: "is invalid"))
    end

    it "should be invalid when experience is negative" do
      candidate_with_negative_experience = Map.merge(valid_attrs, %{experience: Decimal.new(-4)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_negative_experience)

      expect(changeset) |> to(have_errors(experience: {"must be in the range 0-100", [count: Decimal.new(0)]}))
    end

    it "should be invalid when experience is more than or equal to 100" do
      candidate_with_invalid_experience = Map.merge(valid_attrs, %{experience: Decimal.new(100)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_invalid_experience)

      expect(changeset) |> to(have_errors(experience: {"must be in the range 0-100", [count: Decimal.new(100)]}))
    end

    it "should be invalid when no experience is given" do
      candidate_with_no_experience = Map.delete(valid_attrs, :experience)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(have_errors(experience: "can't be blank"))
    end
  end

  context "on delete" do
    it "should raise an exception when it has foreign key reference in other tables" do
      # TODO: Fix factory usage (Ecto 2 will fix it)
      candidate = create(:candidate)
      create(:candidate_interview_schedule, candidate_id: candidate.id, candidate: candidate)

      delete = fn -> Repo.delete!(candidate) end

      expect(delete).to raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      candidate = create(:candidate)

      delete = fn ->  Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end
end
