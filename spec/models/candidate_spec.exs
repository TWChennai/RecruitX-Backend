defmodule RecruitxBackend.CandidateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Candidate

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Repo
  alias Timex.Date

  let :valid_attrs, do: fields_for(:candidate, other_skills: "other skills", role_id: create(:role).id, pipeline_status_id: create(:pipeline_status).id)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Candidate.changeset(%Candidate{}, valid_attrs)

    it do: should be_valid

    it "should be valid when additional information is not given" do
      candidate_with_no_additional_skills = Map.delete(valid_attrs, :other_skills)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_additional_skills)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when experience is 0" do
      candidate_with_no_experience = Map.merge(valid_attrs, %{experience: Decimal.new(0)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when pipeline_status_id is not given and is replaced by default value" do
      candidate_with_no_pipeline_status = Map.delete(valid_attrs, :pipeline_status_id)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_pipeline_status)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when pipeline_status_id is nil and is replaced by default value" do
      candidate_with_no_pipeline_status = Map.merge(valid_attrs, %{pipeline_status_id: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_pipeline_status)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid with the given pipeline_status_id" do
      ps = create(:pipeline_status)
      changeset = Candidate.changeset(%Candidate{}, Map.merge(valid_attrs, %{pipeline_status_id: ps.id}))

      expect(changeset.changes.pipeline_status_id) |> to(be(ps.id))
    end
  end

  context "invalid changeset" do
    subject do: Candidate.changeset(%Candidate{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(first_name: "can't be blank", last_name: "can't be blank", role_id: "can't be blank", experience: "can't be blank")

    it "should be invalid when first_name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs, %{first_name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(first_name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when first_name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs, %{first_name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([first_name: "can't be blank"]))
    end

    it "should be invalid when first_name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs, %{first_name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([first_name: "has invalid format"]))
    end

    it "should be invalid when first_name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs, %{first_name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([first_name: "has invalid format"]))
    end

    it "should be invalid when first_name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs, %{first_name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([first_name: "has invalid format"]))
    end

    it "should be invalid when last_name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs, %{last_name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(last_name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when last_name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs, %{last_name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([last_name: "can't be blank"]))
    end

    it "should be invalid when last_name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs, %{last_name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([last_name: "has invalid format"]))
    end

    it "should be invalid when last_name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs, %{last_name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([last_name: "has invalid format"]))
    end

    it "should be invalid when last_name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs, %{last_name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([last_name: "has invalid format"]))
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
    it "should not raise an exception when it has foreign key reference in other tables" do
      candidate = create(:candidate)
      create(:interview, candidate_id: candidate.id)

      delete = fn -> Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      candidate = create(:candidate)

      delete = fn ->  Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end

  context "query" do
    it "should return candidates in FIFO order" do
      Repo.delete_all(Candidate)

      interview1 = create(:interview, interview_type_id: 1, start_time: Date.now)
      interview2 = create(:interview, interview_type_id: 1, start_time: Date.now |> Date.shift(hours: 1))
      candidate_id1 = interview1.candidate_id
      candidate_id2 = interview2.candidate_id

      [result1, result2] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id]) |> to(be([candidate_id1, candidate_id2]))
    end

    it "should return candidates without interviews last in FIFO order" do
      Repo.delete_all(Candidate)
      candidate_without_interview = create(:candidate)

      interview = create(:interview, interview_type_id: 1, start_time: Date.now)
      candidate_with_interview_id = interview.candidate_id

      [result1, result2] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id]) |> to(be([candidate_with_interview_id, candidate_without_interview.id]))
    end
  end

  context "updateCandidateStatusAsPass" do
    it "should update candidate status as Pass" do
      interview = create(:interview, interview_type_id: 1, start_time: Date.now)
      candidate_id = interview.candidate_id
      # TODO: Magic string!
      pass_id = RecruitxBackend.PipelineStatus.retrieve_by_name("Pass").id

      Candidate.updateCandidateStatusAsPass(candidate_id)

      updated_candidate = Candidate |> Repo.get(candidate_id)

      expect(updated_candidate.pipeline_status_id) |> to(be(pass_id))
    end
  end
end
