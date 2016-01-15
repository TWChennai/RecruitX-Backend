defmodule RecruitxBackend.CandidateInterviewScheduleSpec do
  use ESpec.Phoenix, model: RecruitxBackend.CandidateInterviewSchedule

  import RecruitxBackend.Factory

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateInterviewSchedule
  alias RecruitxBackend.Interview

  let :candidate, do: create(:candidate)
  let :interview, do: create(:interview)

  # TODO: Use factory
  let :valid_attrs, do: %{candidate_id: candidate.id, interview_id: interview.id, candidate_interview_date_time: Ecto.DateTime.cast!("2011-01-01 12:00:00")}
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([candidate_id: "can't be blank", interview_id: "can't be blank"])

    it "when candidate id is nil" do
      candidate_interview_schedule_with_candidate_id_nil = Map.merge(valid_attrs, %{candidate_id: nil})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when interview id is nil" do
      candidate_interview_schedule_with_interview_id_nil = Map.merge(valid_attrs, %{interview_id: nil})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_interview_id_nil)

      expect(result) |> to(have_errors(interview_id: "can't be blank"))
    end

    it "when candidate id is not present" do
      candidate_interview_schedule_with_no_candidate_id = Map.delete(valid_attrs, :candidate_id)

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_no_candidate_id)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when interview id is not present" do
      candidate_interview_schedule_with_no_interview_id = Map.delete(valid_attrs, :interview_id)

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_no_interview_id)

      expect(result) |> to(have_errors(interview_id: "can't be blank"))
    end

    it "when interview_date is nil"
  end

  context "foreign key constraint" do
    it "when candidate id not present in candidates table" do
      # TODO: Not sure why Ectoo.max(Repo, Candidate, :id) is failing - need to investigate
      current_candidate_count = Ectoo.count(Repo, Candidate)
      candidate_id_not_present = current_candidate_count + 1
      candidate_interview_schedule_with_invalid_candidate_id = Map.merge(valid_attrs, %{candidate_id: candidate_id_not_present})

      changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_invalid_candidate_id)

      {:error , error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate_id: "does not exist"]))
    end

    it "when interview id not present in interview table" do
      # TODO: Not sure why Ectoo.max(Repo, Interview, :id) is failing - need to investigate
      current_interview_count = Ectoo.count(Repo, Interview)
      interview_id_not_present = current_interview_count + 1
      candidate_interview_schedule_with_invalid_interview_id = Map.merge(valid_attrs, %{interview_id: interview_id_not_present})

      changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{},candidate_interview_schedule_with_invalid_interview_id)

      {:error , error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_id: "does not exist"]))
    end
end

  context "unique_index constraint will fail" do
    it "when same interview is scheduled more than once for a candidate" do
      changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, valid_attrs)
      Repo.insert(changeset)

      {:error , error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate_interview_id_index: "has already been taken"]))
    end
  end
end
