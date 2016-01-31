defmodule RecruitxBackend.CandidateInterviewScheduleSpec do
  use ESpec.Phoenix, model: RecruitxBackend.CandidateInterviewSchedule

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateInterviewSchedule
  alias RecruitxBackend.InterviewType

  let :valid_attrs, do: fields_for(:candidate_interview_schedule)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([candidate_id: "can't be blank", interview_type_id: "can't be blank"])

    it "when candidate id is nil" do
      candidate_interview_schedule_with_candidate_id_nil = Map.merge(valid_attrs, %{candidate_id: nil})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when candidate id is not present" do
      candidate_interview_schedule_with_no_candidate_id = Map.delete(valid_attrs, :candidate_id)

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_no_candidate_id)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when interview_type id is nil" do
      candidate_interview_schedule_with_interview_id_nil = Map.merge(valid_attrs, %{interview_type_id: nil})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_interview_id_nil)

      expect(result) |> to(have_errors(interview_type_id: "can't be blank"))
    end

    it "when interview id is not present" do
      candidate_interview_schedule_with_no_interview_id = Map.delete(valid_attrs, :interview_type_id)

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_no_interview_id)

      expect(result) |> to(have_errors(interview_type_id: "can't be blank"))
    end

    it "when interview date time is nil" do
      candidate_interview_schedule_with_interview_date_time_nil = Map.merge(valid_attrs, %{candidate_interview_date_time: nil})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_interview_date_time_nil)

      expect(result) |> to(have_errors(candidate_interview_date_time: "can't be blank"))
    end

    it "when interview date time is not present" do
      candidate_interview_schedule_with_no_interview_date_time = Map.delete(valid_attrs, :candidate_interview_date_time)

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_no_interview_date_time)

      expect(result) |> to(have_errors(candidate_interview_date_time: "can't be blank"))
    end

    it "when interview date time is invalid" do
      candidate_interview_schedule_with_candidate_id_nil = Map.merge(valid_attrs, %{candidate_interview_date_time: "invalid"})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_interview_date_time: "is invalid"))
    end

    it "when interview id and date time are  invalid" do
      candidate_interview_schedule_with_candidate_id_nil = Map.merge(valid_attrs, %{interview_type_id: 1.2, candidate_interview_date_time: "invalid"})

      result = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_candidate_id_nil)

      expect(result) |> to(have_errors([interview_type_id: "is invalid", candidate_interview_date_time: "is invalid"]))
    end
  end

  context "foreign key constraint" do
    it "when candidate id not present in candidates table" do
      # TODO: Not sure why Ectoo.max(Repo, Candidate, :id) is failing - need to investigate
      current_candidate_count = Ectoo.count(Repo, Candidate)
      candidate_id_not_present = current_candidate_count + 1
      # TODO: Use factory
      candidate_interview_schedule_with_invalid_candidate_id = Map.merge(valid_attrs, %{candidate_id: candidate_id_not_present})

      changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_with_invalid_candidate_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate: "does not exist"]))
    end

    it "when interview id not present in interview_type table" do
      # TODO: Not sure why Ectoo.max(Repo, InterviewType, :id) is failing - need to investigate
      current_interview_type_count = Ectoo.count(Repo, InterviewType)
      # TODO: Use factory
      interview_type_id_not_present = current_interview_type_count + 1
      candidate_interview_schedule_with_invalid_interview_id = Map.merge(valid_attrs, %{interview_type_id: interview_type_id_not_present})

      changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{},candidate_interview_schedule_with_invalid_interview_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_type: "does not exist"]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same interview is scheduled more than once for a candidate" do
      # TODO: Use factory
      changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, valid_attrs)
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate_interview_id_index: "has already been taken"]))
    end
  end
end
