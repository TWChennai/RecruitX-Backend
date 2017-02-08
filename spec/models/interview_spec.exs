defmodule RecruitxBackend.InterviewSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Interview

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Repo
  alias RecruitxBackend.RoleInterviewType
  alias RecruitxBackend.Slot
  alias RecruitxBackend.TimexHelper

  let :valid_attrs, do: params_with_assocs(:interview)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Interview.changeset(%Interview{}, valid_attrs())

    it do: should be_valid()

    it "should be valid when interview status is present" do
      interview = Map.merge(valid_attrs(), %{interview_status: build(:interview_status)})

      result = Interview.changeset(%Interview{}, interview)

      expect(result) |> to(be_valid())
    end

    it "when interview date time is in the future" do
      future_interview = Map.merge(valid_attrs(), %{start_time: (TimexHelper.utc_now() |> TimexHelper.add(2, :hours))})

      result = Interview.changeset(%Interview{}, future_interview)

      expect(result) |> to(be_valid())
    end

    it "when end_time is not given and is replaced by default value" do
      result = Interview.changeset(%Interview{}, Map.delete(valid_attrs(), :end_time))

      expect(result) |> to(be_valid())
      expect(result.changes.end_time) |> to(be(result.changes.start_time |> TimexHelper.add(1, :hours)))
    end

    it "when end_time is given and is replaced by default value" do
      result = Interview.changeset(%Interview{}, valid_attrs())

      expect(result) |> to(be_valid())
      expect(result.changes.end_time) |> to(be(valid_attrs().start_time |> TimexHelper.add(1, :hours)))
    end

    it "when start_time is updated  and end_time is re-calculated" do
      new_start_time = TimexHelper.utc_now() |> TimexHelper.add(2, :hours)
      attrs_new_start_time = Map.merge(valid_attrs(), %{start_time: new_start_time})
      result = Interview.changeset(%Interview{}, attrs_new_start_time)

      expect(result) |> to(be_valid())
      expect(result.changes.end_time) |> to(be(new_start_time |> TimexHelper.add(1, :hours)))
    end
  end

  context "invalid changeset" do
    subject do: Interview.changeset(%Interview{}, invalid_attrs())

    it do: should_not be_valid()
    it do: should have_errors([candidate_id: {"can't be blank", [validation: :required]}, interview_type_id: {"can't be blank", [validation: :required]}])

    it "when candidate id is nil" do
      interview_with_candidate_id_nil = Map.merge(valid_attrs(), %{candidate_id: nil})

      result = Interview.changeset(%Interview{}, interview_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_id: {"can't be blank", [validation: :required]}))
    end

    it "when candidate id is not present" do
      interview_with_no_candidate_id = Map.delete(valid_attrs(), :candidate_id)

      result = Interview.changeset(%Interview{}, interview_with_no_candidate_id)

      expect(result) |> to(have_errors(candidate_id: {"can't be blank", [validation: :required]}))
    end

    it "when interview_type id is nil" do
      interview_with_interview_id_nil = Map.merge(valid_attrs(), %{interview_type_id: nil})

      result = Interview.changeset(%Interview{}, interview_with_interview_id_nil)

      expect(result) |> to(have_errors(interview_type_id: {"can't be blank", [validation: :required]}))
    end

    it "when interview id is not present" do
      interview_with_no_interview_id = Map.delete(valid_attrs(), :interview_type_id)

      result = Interview.changeset(%Interview{}, interview_with_no_interview_id)

      expect(result) |> to(have_errors(interview_type_id: {"can't be blank", [validation: :required]}))
    end

    it "when interview date time is nil" do
      interview_with_start_time_nil = Map.merge(valid_attrs(), %{start_time: nil})

      result = Interview.changeset(%Interview{}, interview_with_start_time_nil)

      expect(result) |> to(have_errors(start_time: {"can't be blank", [validation: :required]}))
    end

    it "when interview date time is not present" do
      interview_with_no_start_time = Map.delete(valid_attrs(), :start_time)

      result = Interview.changeset(%Interview{}, interview_with_no_start_time)

      expect(result) |> to(have_errors(start_time: {"can't be blank", [validation: :required]}))
    end

    it "when interview date time is invalid" do
      interview_with_invalid_start_time = Map.merge(valid_attrs(), %{start_time: "invalid"})

      result = Interview.changeset(%Interview{}, interview_with_invalid_start_time)

      expect(result) |> to(have_errors(start_time: {"is invalid", [type: Timex.Ecto.DateTime, validation: :cast]}))
    end

    it "when interview date time is in the past" do
      past_interview = Map.merge(valid_attrs(), %{start_time: (TimexHelper.utc_now() |> TimexHelper.add(-2, :hours))})

      result = Interview.changeset(%Interview{}, past_interview)

      expect(result) |> to(have_errors(start_time: {"should be in the future", []}))
    end

    it "when interview id and date time are invalid" do
      invalid_interview = Map.merge(valid_attrs(), %{interview_type_id: 1.2, start_time: "invalid"})

      result = Interview.changeset(%Interview{}, invalid_interview)

      expect(result) |> to(have_errors([interview_type_id: {"is invalid", [type: :id, validation: :cast]}, start_time: {"is invalid", [type: Timex.Ecto.DateTime, validation: :cast]}]))
    end
  end

  context "foreign key constraint" do
    it "when candidate id not present in candidates table" do
      current_candidate_count = Candidate.max(:id)
      candidate_id_not_present = current_candidate_count + 1
      interview_with_invalid_candidate_id = Map.merge(Map.delete(valid_attrs(), :candidate), %{candidate_id: candidate_id_not_present})

      changeset = Interview.changeset(%Interview{}, interview_with_invalid_candidate_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate: {"does not exist", []}]))
    end

    it "when interview id not present in interview_type table" do
      current_interview_type_count = InterviewType.max(:id)
      interview_type_id_not_present = current_interview_type_count + 1
      interview_with_invalid_interview_id = Map.merge(Map.delete(valid_attrs(), :interview_type), %{interview_type_id: interview_type_id_not_present})

      changeset = Interview.changeset(%Interview{},interview_with_invalid_interview_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_type: {"does not exist", []}]))
    end

    it "when interview_status not present in interview_status table" do
      interview_with_invalid_status_id = Map.merge(Map.delete(valid_attrs(), :interview_status), %{interview_status_id: 0})

      changeset = Interview.changeset(%Interview{},interview_with_invalid_status_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_status: {"does not exist", []}]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same interview is scheduled more than once for a candidate" do
      changeset = Interview.changeset(%Interview{}, valid_attrs())
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_type_id: {"has already been taken", []}]))
    end
  end

  context "on delete" do
    it "should not raise an exception when it has foreign key reference in other tables" do
      interview = insert(:interview)
      insert(:interview_panelist, interview: interview)

      delete = fn -> Repo.delete!(interview) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      interview = insert(:interview)

      delete = fn ->  Repo.delete!(interview) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end

  describe "get_interviews_with_associated_data" do
    it "should return interviews of candidates" do
      Repo.delete_all(InterviewPanelist)
      Repo.delete_all(Interview)
      interview = insert(:interview)
      candidate = Candidate |> preload(:candidate_skills)|> Repo.get(interview.candidate_id)

      actual_interview = Interview.get_interviews_with_associated_data |> Repo.one

      expect(actual_interview.candidate) |> to(be(candidate))
      expect(actual_interview.id) |> to(be(interview.id))
      expect(Timex.diff(actual_interview.start_time, interview.start_time, :seconds)) |> to(be(0))
    end

    it "should return empty array when there no interviews" do
      Repo.delete_all(Interview)

      actual_interview_array = Interview.get_interviews_with_associated_data |> Repo.all

      expect(actual_interview_array) |> to(be([]))
    end
  end

  describe "interviews_with_insufficient_panelists" do
    before do: Enum.each([InterviewPanelist, Interview], &Repo.delete_all/1)

    it "should return interviews with no panelists" do
      interview = insert(:interview)

      actual_interview = Interview.interviews_with_insufficient_panelists |> Repo.one

      expect(actual_interview.id) |> to(be(interview.id))
    end

    it "should return interviews with panelists count less than the max_sign_up_limit" do
      interview_panelist = insert(:interview_panelist)

      actual_interview = Interview.interviews_with_insufficient_panelists |> Repo.one

      expect(actual_interview.id) |> to(be(interview_panelist.interview_id))
    end

    it "should return interview when the max_sign_up_limit is one and the interview has no sign_up" do
      interview_type = insert(:interview_type, max_sign_up_limit: 1)
      interview = insert(:interview, interview_type: interview_type)

      result = Interview.interviews_with_insufficient_panelists |> Repo.one

      expect(result.id) |> to(be(interview.id))
    end

    it "should not return interviews with panelists equal to max_sign_up_limit" do
      interview = insert(:interview)
      insert(:interview_panelist, interview: interview, panelist_login_name: "dinesh")
      insert(:interview_panelist, interview: interview, panelist_login_name: "ashwin")

      actual_interviews = Interview.interviews_with_insufficient_panelists |> Repo.all
      list = Enum.filter(actual_interviews, &(&1.id == interview.id))
      expect(list) |> to(be([]))
    end
  end

  describe "update_status" do
    before do: Repo.delete_all(InterviewStatus)

    it "should not update interview when status is already entered" do
      interview = insert(:interview)
      interview_status = insert(:interview_status)
      Interview.update_status(interview.id, interview_status.id) |> Repo.transaction

      {_, _, changeset, _} = Interview.update_status(interview.id, interview_status.id) |> Repo.transaction

      expected_error = [interview_status: {"Feedback has already been entered", []}]
      expect changeset.errors |> to(be(expected_error))
    end

    it "should not update interview when status is invalid" do
      interview = insert(:interview)
      {_, _, changeset, _} = Interview.update_status(interview.id, 0) |> Repo.transaction
      expected_error = [interview_status: {"does not exist", []}]

      expect changeset.errors |> to(be(expected_error))
    end

    it "should update status and not delete other interviews,panelists for a candidate when status is not Pass" do
      interview = insert(:interview)
      interview_status = insert(:interview_status)
      interview_to_be_retained = insert(:interview, candidate: interview.candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(7, :days))
      panelists_to_be_retained = insert(:interview_panelist, interview: interview_to_be_retained)

      Interview.update_status(interview.id, interview_status.id) |> Repo.transaction

      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(!is_nil(Interview |> Repo.get(interview_to_be_retained.id))) |> to(be_true())
      expect(!is_nil(InterviewPanelist |> Repo.get(panelists_to_be_retained.id))) |> to(be_true())
    end

    it "should update status and delete future interviews,panelists when status is Pass" do
      future_date = TimexHelper.utc_now() |> TimexHelper.add(7, :days)
      interview = insert(:interview, start_time: TimexHelper.utc_now())
      future_interview = insert(:interview, candidate: interview.candidate, start_time: future_date)
      future_panelist = insert(:interview_panelist, interview: future_interview)
      interview_status = insert(:interview_status, name: PipelineStatus.pass)
      pass_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id

      Interview.update_status(interview.id, interview_status.id) |> Repo.transaction

      updated_interview = Interview |> Repo.get(interview.id)
      updated_candidate = Candidate |> Repo.get(interview.candidate_id)
      expect(updated_candidate.pipeline_status_id) |> to(be(pass_id))
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(Interview |> Repo.get(future_interview.id)) |> to(be_nil())
      expect(InterviewPanelist |> Repo.get(future_panelist.id)) |> to(be_nil())
    end

    it "should update status and not delete past interviews,panelists when status is Pass" do
      past_date = TimexHelper.utc_now() |> TimexHelper.add(-7, :days)
      interview = insert(:interview, start_time: TimexHelper.utc_now())
      interview_to_be_retained = insert(:interview, candidate: interview.candidate, start_time: past_date)
      panelists_to_be_retained = insert(:interview_panelist, interview: interview_to_be_retained)
      interview_status = insert(:interview_status, name: PipelineStatus.pass)
      pass_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id

      Interview.update_status(interview.id, interview_status.id) |> Repo.transaction

      updated_interview = Interview |> Repo.get(interview.id)
      updated_candidate = Candidate |> Repo.get(interview.candidate_id)
      expect(updated_candidate.pipeline_status_id) |> to(be(pass_id))
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(!is_nil(Interview |> Repo.get(interview_to_be_retained.id))) |> to(be_true())
      expect(!is_nil(InterviewPanelist |> Repo.get(panelists_to_be_retained.id))) |> to(be_true())
    end

    it "should update status when status is Pass and there are no successive rounds" do
      interview = insert(:interview)
      interview_status = insert(:interview_status, name: PipelineStatus.pass)
      pass_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id

      Interview.update_status(interview.id, interview_status.id) |> Repo.transaction

      updated_interview = Interview |> Repo.get(interview.id)
      updated_candidate = Candidate |> Repo.get(interview.candidate_id)
      expect(updated_candidate.pipeline_status_id) |> to(be(pass_id))
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
    end
  end

  describe "get_last_completed_rounds_start_time_for_candidate" do
    it "should return the minimum possible date if no interviews are there for a candidate" do
      candidate = insert(:candidate)
      expected_value = TimexHelper.from_epoch(date: {0, 0, 1})

      actual_value = Interview.get_last_completed_rounds_start_time_for(candidate.id)

      expect(actual_value) |> to(be(expected_value))
    end

    it "should return the minimum possible date if all interviews are with status_id as nil for a candidate" do
      interview1 = insert(:interview)
      insert(:interview, candidate: interview1.candidate)
      candidate = Candidate |> Repo.get(interview1.candidate_id)
      expected_value = TimexHelper.from_epoch(date: {0, 0, 1})

      actual_value = Interview.get_last_completed_rounds_start_time_for(candidate.id)

      expect(actual_value) |> to(be(expected_value))
    end

    it "should return the start date of a interview if candidate have one interview with status_id as not nil" do
      interview_status = insert(:interview_status)
      interview = insert(:interview, interview_status: interview_status)
      candidate = Candidate |> Repo.get(interview.candidate_id)
      expected_value = interview.start_time

      actual_value = Interview.get_last_completed_rounds_start_time_for(candidate.id)

      expect(Timex.diff(actual_value, expected_value, :seconds)) |> to(be(0))
    end

    it "should return the maximum start date of a interview with if candidate have more than one interview with status_id as not nil" do
      now = TimexHelper.utc_now()
      interview_status = insert(:interview_status)
      interview1 = insert(:interview, interview_status: interview_status, start_time: now)
      interview2 = insert(:interview, interview_status: interview_status, start_time: now |> TimexHelper.add(1, :hours), candidate: interview1.candidate)
      candidate = Candidate |> Repo.get(interview2.candidate_id)
      expected_value = interview2.start_time

      actual_value = Interview.get_last_completed_rounds_start_time_for(candidate.id)

      expect(Timex.diff(actual_value, expected_value, :seconds)) |> to(be(0))
    end
  end

  describe "get_last_completed_rounds_status_for" do
    it "should return true for first interviews" do
      candidate = insert(:candidate)
      interview = insert(:interview, candidate: candidate)

      actual_value = Interview.get_last_completed_rounds_status_for(candidate.id, interview.start_time )

      expect(actual_value) |> to(be(true))
    end

    it "should return true if previous interview has feedback" do
      candidate = insert(:candidate)
      insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now()|> TimexHelper.add(-1, :days), interview_status_id: 1)
      interview2 = insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now())

      actual_value = Interview.get_last_completed_rounds_status_for(candidate.id, interview2.start_time )

      expect(actual_value) |> to(be(true))
    end

    it "should return false if previous interview has NO feedback" do
      candidate = insert(:candidate)
      insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now()|> TimexHelper.add(-1, :days))
      interview2 = insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now())

      actual_value = Interview.get_last_completed_rounds_status_for(candidate.id, interview2.start_time )

      expect(actual_value) |> to(be(false))
    end
  end

  describe "get_previous_round" do
    it "should return previous round of same candidate" do
      technical_one = InterviewType.retrieve_by_name(InterviewType.technical_1)
      technical_two = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = insert(:candidate)
      technical_one_interview = insert(:interview, candidate: candidate, interview_type: technical_one)
      insert(:interview, candidate: candidate, interview_type: technical_two)

      [actual_value] = Interview.get_previous_round(candidate.id, technical_two.id)

      expect(actual_value.id) |> to(be(technical_one_interview.id))
    end

    it "should return empty if there are no previous interview" do
      coding = InterviewType.retrieve_by_name(InterviewType.coding)
      candidate = insert(:candidate)
      insert(:interview, candidate: candidate, interview_type: coding)

      actual_value = Interview.get_previous_round(candidate.id, coding.id)

      expect(actual_value) |> to(be([]))
    end
  end

  describe "validation for updating the interview schedule" do
    let :tomorrow, do: TimexHelper.utc_now() |> TimexHelper.add(1, :days)
    let :candidate, do: insert(:candidate)
    let :code_pairing_interview_type, do: insert(:interview_type, priority: 0, name: "CP")
    let :technical_one_interview_type, do: insert(:interview_type, priority: 2, name: "T1")
    let :technical_two_interview_type, do: insert(:interview_type, priority: 3, name: "T2")
    let :leadership_interview_type, do: insert(:interview_type, priority: 4, name: "LD")
    let :p3_interview_type, do: insert(:interview_type, priority: 4, name: "Pthree")

    it "should not allow interview with less priority to happen before interview with high priority" do
      code_pairing = insert(:interview, interview_type: code_pairing_interview_type(), candidate: candidate(), start_time: tomorrow())
      insert(:interview, interview_type: technical_one_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(2, :hours))

      changeset = Interview.changeset(code_pairing |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(1.01, :hours)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be({"should be before T1 atleast by 1 hour", []}))
    end

    it "should not allow interview with high priority to happen after interview with low priority" do
      insert(:interview, interview_type: code_pairing_interview_type(), candidate: candidate(), start_time: tomorrow(), end_time: tomorrow() |> TimexHelper.add(1, :hours))
      technical_one = insert(:interview, interview_type: technical_one_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(2, :hours))

      changeset = Interview.changeset(technical_one |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(-1.01, :hours)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be({"should be after CP atleast by 1 hour", []}))
    end

    it "should not allow interview to be scheduled after interview with high priority and before interview with low priority" do
      insert(:interview, interview_type: code_pairing_interview_type(), candidate: candidate(), start_time: tomorrow())
      technical_one = insert(:interview, interview_type: technical_one_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(1, :hours))
      insert(:interview, interview_type: technical_two_interview_type(), candidate: candidate(), start_time: tomorrow()
      |> TimexHelper.add(1.5, :hours))

      changeset = Interview.changeset(technical_one |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(0.75, :hours)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be({"should be after CP and before T2 atleast by 1 hour", []}))
    end

    it "should allow interview with high priority to happen after interview with low priority" do
      insert(:interview, interview_type: code_pairing_interview_type(), candidate: candidate(), start_time: tomorrow())
      technical_one = insert(:interview, interview_type: technical_one_interview_type(), candidate: candidate(), start_time: tomorrow()
      |> TimexHelper.add(2, :hours))

      changeset = Interview.changeset(technical_one |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(2, :days)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be(nil))
    end

    it "should allow interview with low priority to happen before interview with high priority" do
      code_pairing = insert(:interview, interview_type: code_pairing_interview_type(), candidate: candidate(), start_time: tomorrow())
      insert(:interview, interview_type: technical_one_interview_type(), candidate: candidate(), start_time: tomorrow()
      |> TimexHelper.add(4, :hours))

      changeset = Interview.changeset(code_pairing |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(-2, :hours)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be(nil))
    end

    it "should allow interview with lowest priority to be modified without any constraint" do
      code_pairing = insert(:interview, interview_type: code_pairing_interview_type(), candidate: candidate(), start_time: tomorrow())

      changeset = Interview.changeset(code_pairing |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(-2, :hours)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be(nil))
    end

    describe "comparison with interviews of same priority based on start_time" do
      before do
        insert(:interview, interview_type: technical_one_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(1, :hours))
      end

      let :technical_two, do: insert(:interview, interview_type: technical_two_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(2, :hours))

      it "should use the interview with lowest start time for comparison" do
        insert(:interview, interview_type: p3_interview_type(), candidate: candidate(), start_time: tomorrow()
        |> TimexHelper.add(3, :hours))
        insert(:interview, interview_type: leadership_interview_type(), candidate: candidate(), start_time: tomorrow()
        |> TimexHelper.add(6, :hours))

        changeset = Interview.changeset(technical_two() |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(4, :hours)})
        changeset = Interview.validate_with_other_rounds(changeset)

        expect changeset.errors[:start_time] |> to(be({"should be after T1 and before Pthree atleast by 1 hour", []}))
      end

      it "should use the interview with lowest start time for comparison" do
        insert(:interview, interview_type: p3_interview_type(), candidate: candidate(), start_time: tomorrow()
        |> TimexHelper.add(6, :hours))
        insert(:interview, interview_type: leadership_interview_type(), candidate: candidate(), start_time: tomorrow()
        |> TimexHelper.add(3, :hours))

        changeset = Interview.changeset(technical_two() |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(4, :hours)})
        changeset = Interview.validate_with_other_rounds(changeset)

        expect changeset.errors[:start_time] |> to(be({"should be after T1 and before LD atleast by 1 hour", []}))
      end
    end

    describe "comparison with interviews of same priority" do
      before do
        insert(:interview, interview_type: technical_two_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(2, :hours))
      end

      it "should return nil when there is no clash with same priority round" do
        p3 = insert(:interview, interview_type: p3_interview_type(), candidate: candidate(), start_time: tomorrow()
        |> TimexHelper.add(6, :hours))
        insert(:interview, interview_type: leadership_interview_type(), candidate: candidate(), start_time: tomorrow()
        |> TimexHelper.add(3, :hours))

        changeset = Interview.changeset(p3 |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(4, :hours)})
        changeset = Interview.validate_with_other_rounds(changeset)

        expect changeset.errors[:start_time] |> to(be(nil))
      end

      it "should return error message when there is clash with same priority round" do
        p3 = insert(:interview, interview_type: p3_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(6, :hours), end_time: tomorrow() |> TimexHelper.add(7, :hours))
        insert(:interview, interview_type: leadership_interview_type(), candidate: candidate(), start_time: tomorrow() |> TimexHelper.add(3, :hours), end_time: tomorrow() |> TimexHelper.add(4, :hours))

        changeset = Interview.changeset(p3 |> Repo.preload(:interview_type), %{"start_time" => tomorrow() |> TimexHelper.add(2.1, :hours)})
        changeset = Interview.validate_with_other_rounds(changeset)

        expect changeset.errors[:start_time] |> to(be({"should be after T2 and before/after LD atleast by 1 hour", []}))
      end
    end
  end

  context "get_candidates_with_all_rounds_completed" do
    before do: Enum.each([Candidate, Slot, InterviewType], &Repo.delete_all/1)

    it "should return all candidates who have completed no of rounds with start_time of last interview" do
      interview1 = insert(:interview, start_time: TimexHelper.utc_now())
      interview2 = insert(:interview, candidate: interview1.candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))

      [[candidate_id, last_interview_start_time, completed_rounds]] = (Interview.get_candidates_with_all_rounds_completed) |> Repo.all

      expect(candidate_id) |> to(be(interview2.candidate_id))
      expect(Timex.diff(last_interview_start_time, interview2.start_time, :seconds)) |> to(be(0))
      expect(completed_rounds) |> to(be(2))
    end

    it "should return [] when candidate has no interview rounds" do
      insert(:candidate)

      result = (Interview.get_candidates_with_all_rounds_completed) |> Repo.all
      expect(result) |> to(be([]))
    end
  end

  context "get_last_interview_status_for" do
    before do: Enum.each([Candidate, Slot, InterviewType, RoleInterviewType], &Repo.delete_all/1)

    it "should add status of last interview if pipeline is closed and candidate has finished all rounds" do
      interview_type1 = insert(:interview_type)
      interview_type2 = insert(:interview_type)
      candidate = insert(:candidate, pipeline_status: PipelineStatus.retrieve_by_name(PipelineStatus.closed))
      insert(:role_interview_type, role: candidate.role, interview_type: interview_type1)
      insert(:role_interview_type, role: candidate.role, interview_type: interview_type2)
      interview_data1 = params_for(:interview, candidate: candidate, interview_type: interview_type1, start_time: TimexHelper.utc_now())
      interview_data2 = params_for(:interview,
        candidate: candidate,
        interview_type: interview_type2,
        interview_status: build(:interview_status),
        start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))
      total_no_of_interview_types = Enum.count(Repo.all(RoleInterviewType))
      Repo.insert(Interview.changeset(%Interview{}, interview_data1))
      Repo.insert(Interview.changeset(%Interview{}, interview_data2))

      last_status = Interview.get_last_interview_status_for(candidate, [[candidate.id, interview_data2.start_time, total_no_of_interview_types]])

      expect(last_status) |> to(be(interview_data2.interview_status_id))
    end

    it "should add status of last interview if pipeline is closed and if that last interview is pass" do
      pass = InterviewStatus.retrieve_by_name("Pass")
      interview_type1 = insert(:interview_type)
      interview_type2 = insert(:interview_type)
      candidate = insert(:candidate, pipeline_status: PipelineStatus.retrieve_by_name(PipelineStatus.closed))
      interview_data1 = params_for(:interview, candidate: candidate, interview_type: interview_type1, start_time: TimexHelper.utc_now())
      interview_data2 = params_for(:interview,
        candidate: candidate,
        interview_type: interview_type2,
        interview_status: pass,
        start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))
      total_no_of_interview_types = Enum.count(Repo.all(InterviewType))
      Repo.insert(Interview.changeset(%Interview{}, interview_data1))
      Repo.insert(Interview.changeset(%Interview{}, interview_data2))

      last_status = Interview.get_last_interview_status_for(candidate, [[candidate.id, interview_data2.start_time, total_no_of_interview_types]])

      expect(last_status) |> to(be(interview_data2.interview_status_id))
    end

    it "should not add status of last interview if pipeline is open and candidate has finished all rounds" do
      interview_type1 = insert(:interview_type)
      interview_type2 = insert(:interview_type)
      candidate = insert(:candidate)
      interview_data1 = params_for(:interview, candidate: candidate, interview_type: interview_type1, start_time: TimexHelper.utc_now())
      interview_data2 = params_for(:interview,
        candidate: candidate,
        interview_type: interview_type2,
        interview_status: build(:interview_status),
        start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))
      total_no_of_interview_types = Enum.count(Repo.all(InterviewType))
      Repo.insert(Interview.changeset(%Interview{}, interview_data1))
      Repo.insert(Interview.changeset(%Interview{}, interview_data2))

      last_status = Interview.get_last_interview_status_for(candidate, [[candidate.id, interview_data2.start_time, total_no_of_interview_types]])

      expect(last_status) |> to(be(nil))
    end
  end

  context "should_less_than_a_month" do
    it "should insert error into changeset if start_time is more than a month" do
      interview = Map.merge(valid_attrs(), %{start_time: TimexHelper.utc_now() |> TimexHelper.add(32, :days)})

      result = Interview.changeset(%Interview{}, interview)
      expect(result) |> to(have_errors(start_time: {"should be less than a month", []}))
    end

    it "should not insert error into changeset if start_time is less than a month" do
      interview = Map.merge(valid_attrs(), %{start_time: TimexHelper.utc_now()})

      result = Interview.changeset(%Interview{}, interview)
      expect(result) |> to(be_valid())
    end
  end

  context "is_in_future" do
    it "should insert error into changeset if start_time is in past" do
      interview = Map.merge(valid_attrs(), %{start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :hours)})

      result = Interview.changeset(%Interview{}, interview)
      expect(result) |> to(have_errors(start_time: {"should be in the future", []}))
    end

    it "should not insert error into changeset if start_time is in future" do
      interview = Map.merge(valid_attrs(), %{start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours)})

      result = Interview.changeset(%Interview{}, interview)
      expect(result) |> to(be_valid())
    end
  end

  context "format interview" do
    it "should contain interview names and dates for the candidate in the result" do
      interview_type = insert(:interview_type)
      interview = insert(:interview, interview_type: interview_type)

      formatted_interview = Interview
        |> preload([:interview_type])
        |> Repo.get(interview.id)
        |> Interview.format

      expect(formatted_interview.name) |> to(be(interview_type.name))
      expect(formatted_interview.date) |> to(be(TimexHelper.format(interview.start_time, "%b-%d")))
    end
  end

  context "format interview with result and panelist" do
    it "should contain interview names, date, result, panelists for the candidate in the result" do
      interview_type = insert(:interview_type)
      interview_status = insert(:interview_status)
      interview = insert(:interview, interview_type: interview_type, interview_status: interview_status)

      interview_panelist = insert(:interview_panelist, interview: interview, panelist_login_name: "test1")
      interview_date = TimexHelper.format_with_timezone(interview.start_time, "%d/%m/%y")

      input_interview = Interview |> preload([:interview_panelist, :interview_status, :interview_type]) |> Repo.get(interview.id)

      formatted_interview = Interview.format_with_result_and_panelist(input_interview)

      expect(formatted_interview.name) |> to(be(interview_type.name))
      expect(formatted_interview.result) |> to(be(interview_status.name))
      expect(formatted_interview.date) |> to(be(interview_date))
      expect(formatted_interview.panelists) |> to(be(interview_panelist.panelist_login_name))
    end
  end

  context "get the interviews in the past 5 days" do
    before do: Repo.delete_all(Interview)

    it "should return the interview from the past 5 days" do
      insert(:interview, id: 900, start_time: get_start_of_current_week())
      insert(:interview, id: 901, start_time: get_start_of_current_week() |> TimexHelper.add(-1, :days))
      insert(:interview, id: 902, start_time: get_start_of_current_week() |> TimexHelper.add(+7, :days))

      actual_result = Interview |> Interview.working_days_in_current_week |> Repo.one

      expect(actual_result.id) |> to(be(900))
    end
  end

  context "get the tuesday to friday of a week" do
    before do: Repo.delete_all(Interview)

    it "should return the interview from the next week" do
      insert(:interview, id: 900, start_time: get_start_of_current_week() |> TimexHelper.add(+3, :days))
      insert(:interview, id: 901, start_time: get_start_of_current_week() |> TimexHelper.add(-8, :days))
      insert(:interview, id: 902, start_time: get_start_of_current_week() |> TimexHelper.add(+6, :days))

      actual_result = Interview |> Interview.tuesday_to_friday_of_the_current_week |> Repo.one

      expect(actual_result.id) |> to(be(900))
    end
  end
end
