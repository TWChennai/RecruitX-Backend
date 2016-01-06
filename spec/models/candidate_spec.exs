defmodule RecruitxBackend.CandidateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Candidate

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Role

  let :role, do: Repo.insert!(%Role{name: "test_role"})
  let :valid_attrs, do: %{name: "some content", experience: Decimal.new(3.3), role_id: role.id, additional_information: "info"}
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Candidate.changeset(%Candidate{}, valid_attrs)

    it do: should be_valid

    it "should be valid when additional information is not given" do
      candidate_with_no_additional_information = Dict.delete(valid_attrs, :additional_information)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_additional_information)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when experience is 0" do
      candidate_with_no_experience = Dict.merge(valid_attrs, %{experience: Decimal.new(0)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(be_valid)
    end
  end

  context "invalid changeset" do
    subject do: Candidate.changeset(%Candidate{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank", role_id: "can't be blank", experience: "can't be blank")

    it "should be invalid when name is an empty string" do
      candidate_with_empty_name = Dict.merge(valid_attrs, %{name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is nil" do
      candidate_with_nil_name = Dict.merge(valid_attrs, %{name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([name: "can't be blank"]))
    end

    it "should be invalid when name is a blank string" do
      candidte_with_blank_name = Dict.merge(valid_attrs, %{name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name is only numbers" do
      candidate_with_numbers_name = Dict.merge(valid_attrs, %{name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when name starts with space" do
      candidate_starting_with_space_name = Dict.merge(valid_attrs, %{name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([name: "has invalid format"]))
    end

    it "should be invalid when experience is nil" do
      candidate_with_nil_experience = Dict.merge(valid_attrs, %{experience: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_experience)

      expect(changeset) |> to(have_errors(experience: "can't be blank"))
    end

    it "should be invalid when experience is an empty string" do
      candidate_with_empty_experience = Dict.merge(valid_attrs, %{experience: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_experience)

      expect(changeset) |> to(have_errors(experience: "is invalid"))
    end

    it "should be invalid when experience is negative" do
      candidate_with_negative_experience = Dict.merge(valid_attrs, %{experience: Decimal.new(-4)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_negative_experience)

      expect(changeset) |> to(have_errors(experience: {"must be greater than or equal to %{count}", [count: Decimal.new(0)]}))
    end

    it "should be invalid when experience is more than or equal to 100" do
      candidate_with_invalid_experience = Dict.merge(valid_attrs, %{experience: Decimal.new(100)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_invalid_experience)

      expect(changeset) |> to(have_errors(experience: {"must be less than %{count}", [count: Decimal.new(100)]}))
    end

    it "should be invalid when no experience is given" do
      candidate_with_no_experience = Dict.delete(valid_attrs, :experience)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(have_errors(experience: "can't be blank"))
    end
  end

  context "on delete" do
    it "should raise an exception when it has foreign key reference in other tables" do
      candidate_changeset = Candidate.changeset(%Candidate{}, valid_attrs)
      candidate = Repo.insert!(candidate_changeset)
      interview = Repo.insert!(%RecruitxBackend.Interview{name: "some_interview"})
      valid_attrs_for_candidate_interview_schedule = %{candidate_id: candidate.id, interview_id: interview.id, interview_date: Ecto.Date.cast!("2016-01-01"), interview_time: Ecto.Time.cast!("12:00:00")}
      changeset_for_candidate_interview_schedule = RecruitxBackend.CandidateInterviewSchedule.changeset(%RecruitxBackend.CandidateInterviewSchedule{}, valid_attrs_for_candidate_interview_schedule)
      Repo.insert(changeset_for_candidate_interview_schedule)

      delete = fn ->  Repo.delete!(candidate) end

      expect(delete).to raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      candidate_changeset = Candidate.changeset(%Candidate{}, valid_attrs)
      candidate = Repo.insert(candidate_changeset)

      delete = fn ->  Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end
end