defmodule RecruitxBackend.InterviewSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Interview

  alias RecruitxBackend.Interview

  let :valid_attrs, do: %{name: "some content", priority: 42}
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Interview.changeset(%Interview{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: Interview.changeset(%Interview{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(name: "can't be blank")

    it "should be invalid when name is an empty string" do
      interview_with_empty_name = Dict.merge(valid_attrs, %{name: ""})
      changeset = Interview.changeset(%Interview{}, interview_with_empty_name)

      expect(changeset) |> to(have_errors(name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when name is a blank string"

    it "should be valid when priority is nil" do
      interview_with_nil_priority = Dict.merge(valid_attrs, %{priority: nil})
      changeset = Interview.changeset(%Interview{}, interview_with_nil_priority)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when no priority is given" do
      interview_with_no_priority = Dict.delete(valid_attrs, :priority)
      changeset = Interview.changeset(%Interview{}, interview_with_no_priority)

      expect(changeset) |> to(be_valid)
    end
  end

  context "unique_constraint" do
    it "should be invalid when interview already exists with same name" do
      valid_interview = Interview.changeset(%Interview{}, valid_attrs)
      Repo.insert!(valid_interview)

      {:error, changeset} = Repo.insert(valid_interview)
      expect(changeset) |> to(have_errors(name: "has already been taken"))
    end
  end
  context "on delete" do
    it "should raise an exception when it has foreign key references in other tables" do
      role = Repo.insert!(%RecruitxBackend.Role{name: "test_role"})
      candidate = Repo.insert!(%RecruitxBackend.Candidate{name: "some content", experience: Decimal.new(3.3), role_id: role.id, additional_information: "info"})
      interview = Repo.insert!(%RecruitxBackend.Interview{name: "some_interview"})
      Repo.insert!(%RecruitxBackend.CandidateInterviewSchedule{candidate_id: candidate.id, interview_id: interview.id, interview_date: Ecto.Date.cast!("2011-01-01"), interview_time: Ecto.Time.cast!("12:00:00")})

      delete = fn ->  Repo.delete!(interview) end

      expect(delete).to raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      interview_changeset = Interview.changeset(%Interview{}, valid_attrs)
      interview = Repo.insert(interview_changeset)

      delete = fn -> Repo.delete!(interview) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end
end
