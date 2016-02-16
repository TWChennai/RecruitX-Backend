defmodule RecruitxBackend.InterviewSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Interview

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.Repo
  alias Timex.Date

  let :valid_attrs, do: fields_for(:interview)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: Interview.changeset(%Interview{}, valid_attrs)

    it do: should be_valid

    it "should be valid when interview status is present" do
      interview = Map.merge(valid_attrs, %{interview_status_id: create(:interview_status).id})

      result = Interview.changeset(%Interview{}, interview)

      expect(result) |> to(be_valid)
    end
  end

  context "invalid changeset" do
    subject do: Interview.changeset(%Interview{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([candidate_id: "can't be blank", interview_type_id: "can't be blank"])

    it "when candidate id is nil" do
      interview_with_candidate_id_nil = Map.merge(valid_attrs, %{candidate_id: nil})

      result = Interview.changeset(%Interview{}, interview_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when candidate id is not present" do
      interview_with_no_candidate_id = Map.delete(valid_attrs, :candidate_id)

      result = Interview.changeset(%Interview{}, interview_with_no_candidate_id)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when interview_type id is nil" do
      interview_with_interview_id_nil = Map.merge(valid_attrs, %{interview_type_id: nil})

      result = Interview.changeset(%Interview{}, interview_with_interview_id_nil)

      expect(result) |> to(have_errors(interview_type_id: "can't be blank"))
    end

    it "when interview id is not present" do
      interview_with_no_interview_id = Map.delete(valid_attrs, :interview_type_id)

      result = Interview.changeset(%Interview{}, interview_with_no_interview_id)

      expect(result) |> to(have_errors(interview_type_id: "can't be blank"))
    end

    it "when interview date time is nil" do
      interview_with_start_time_nil = Map.merge(valid_attrs, %{start_time: nil})

      result = Interview.changeset(%Interview{}, interview_with_start_time_nil)

      expect(result) |> to(have_errors(start_time: "can't be blank"))
    end

    it "when interview date time is not present" do
      interview_with_no_start_time = Map.delete(valid_attrs, :start_time)

      result = Interview.changeset(%Interview{}, interview_with_no_start_time)

      expect(result) |> to(have_errors(start_time: "can't be blank"))
    end

    it "when interview date time is invalid" do
      interview_with_candidate_id_nil = Map.merge(valid_attrs, %{start_time: "invalid"})

      result = Interview.changeset(%Interview{}, interview_with_candidate_id_nil)

      expect(result) |> to(have_errors(start_time: "is invalid"))
    end

    it "when interview id and date time are  invalid" do
      interview_with_candidate_id_nil = Map.merge(valid_attrs, %{interview_type_id: 1.2, start_time: "invalid"})

      result = Interview.changeset(%Interview{}, interview_with_candidate_id_nil)

      expect(result) |> to(have_errors([interview_type_id: "is invalid", start_time: "is invalid"]))
    end
  end

  context "foreign key constraint" do
    it "when candidate id not present in candidates table" do
      # TODO: Not sure why Ectoo.max(Repo, Candidate, :id) is failing - need to investigate
      current_candidate_count = Ectoo.count(Repo, Candidate)
      candidate_id_not_present = current_candidate_count + 1
      # TODO: Use factory
      interview_with_invalid_candidate_id = Map.merge(valid_attrs, %{candidate_id: candidate_id_not_present})

      changeset = Interview.changeset(%Interview{}, interview_with_invalid_candidate_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate: "does not exist"]))
    end

    it "when interview id not present in interview_type table" do
      # TODO: Not sure why Ectoo.max(Repo, InterviewType, :id) is failing - need to investigate
      current_interview_type_count = Ectoo.count(Repo, InterviewType)
      # TODO: Use factory
      interview_type_id_not_present = current_interview_type_count + 1
      interview_with_invalid_interview_id = Map.merge(valid_attrs, %{interview_type_id: interview_type_id_not_present})

      changeset = Interview.changeset(%Interview{},interview_with_invalid_interview_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_type: "does not exist"]))
    end

    it "when interview_status not present in interview_status table" do
      interview_with_invalid_status_id = Map.merge(valid_attrs, %{interview_status_id: 0})

      changeset = Interview.changeset(%Interview{},interview_with_invalid_status_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_status: "does not exist"]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same interview is scheduled more than once for a candidate" do
      # TODO: Use factory
      changeset = Interview.changeset(%Interview{}, valid_attrs)
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview_type_id: "has already been taken"]))
    end
  end

  context "on delete" do
    it "should raise an exception when it has foreign key reference in other tables" do
      interview = create(:interview)
      create(:interview_panelist, interview_id: interview.id)

      delete = fn -> Repo.delete!(interview) end

      expect(delete).to raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      interview = create(:interview)

      delete = fn ->  Repo.delete!(interview) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end

  context "default_order" do
    before do: Repo.delete_all(Interview)

    it "should sort by ascending order of start time" do
      now = Timex.Date.now
      interview_with_start_date1 = create(:interview, start_time: now |> Timex.Date.shift(days: 1))
      interview_with_start_date2 = create(:interview, start_time: now |> Timex.Date.shift(days: 3))
      interview_with_start_date3 = create(:interview, start_time: now |> Timex.Date.shift(days: -2))
      interview_with_start_date4 = create(:interview, start_time: now |> Timex.Date.shift(days: -5))

      [interview1, interview2, interview3, interview4] = Interview |> Interview.default_order |> Repo.all

      expect(interview1.start_time) |> to(eq(interview_with_start_date4.start_time))
      expect(interview2.start_time) |> to(eq(interview_with_start_date3.start_time))
      expect(interview3.start_time) |> to(eq(interview_with_start_date1.start_time))
      expect(interview4.start_time) |> to(eq(interview_with_start_date2.start_time))
    end

    it "should tie-break on id for the same start time" do
      now = Timex.Date.now
      interview_with_start_date1 = create(:interview, start_time: now |> Timex.Date.shift(days: 1), id: 1)
      interview_with_same_start_date1 = create(:interview, start_time: now |> Timex.Date.shift(days: 1), id: interview_with_start_date1.id + 1)
      interview_with_start_date2 = create(:interview, start_time: now |> Timex.Date.shift(days: 2))

      [interview1, interview2, interview3] = Interview |> Interview.default_order |> Repo.all

      expect(interview1.start_time) |> to(eq(interview_with_start_date1.start_time))
      expect(interview2.start_time) |> to(eq(interview_with_same_start_date1.start_time))
      expect(interview3.start_time) |> to(eq(interview_with_start_date2.start_time))
    end
  end

  describe "query" do
    context "get_candidate_ids_interviewed_by" do
      before do:  Repo.delete_all(InterviewPanelist)

      it "should return no candidate_ids when none were interviewed by panelist" do
        candidate_ids = Repo.all Interview.get_candidate_ids_interviewed_by("dummy")

        expect(candidate_ids) |> to(be([]))
      end

      it "should return candidate_ids who were interviewed by panelist" do
        interview1 = create(:interview)
        interview2 = create(:interview)
        create(:interview_panelist, interview_id: interview1.id, panelist_login_name: "test")
        create(:interview_panelist, interview_id: interview2.id, panelist_login_name: "test")

        candidate_ids = Repo.all Interview.get_candidate_ids_interviewed_by("test")

        expect(Enum.sort(candidate_ids)) |> to(be([interview1.candidate_id, interview2.candidate_id]))

      end

      it "should not return candidate_ids who were not interviewed by panelist" do
        candidateInterviewed = create(:candidate)
        candidateNotInterviewed = create(:candidate)

        interview1 = create(:interview, candidate: candidateInterviewed, candidate_id: candidateInterviewed.id)
        interview2 = create(:interview, candidate: candidateNotInterviewed, candidate_id: candidateNotInterviewed.id)

        create(:interview_panelist, interview_id: interview1.id, panelist_login_name: "test")
        create(:interview_panelist, interview_id: interview2.id, panelist_login_name: "dummy")

        candidate_ids = Repo.all Interview.get_candidate_ids_interviewed_by("test")

        expect(candidate_ids) |> to(be([interview1.candidate_id]))
      end
    end
  end

  describe "is_signup_lesser_than" do
    it "should return true when there are no signups" do
      interview = create(:interview)
      allow Repo |> to(accept(:all, fn(_) -> [] end))

      expect(Interview.is_signup_lesser_than(interview.id, 2)) |> to(be_true)
    end

    it "should return true when signups are lesser than max" do
      interview = create(:interview)
      allow Repo |> to(accept(:all, fn(_) -> [%{"interview_id": interview.id, "signup_count": 1, "interview_type": 1}] end))

      expect(Interview.is_signup_lesser_than(interview.id, 2)) |> to(be_true)
    end

    it "should return false when signups are greater than max" do
      interview = create(:interview)
      allow Repo |> to(accept(:all, fn(_) -> [%{"interview_id": interview.id, "signup_count": 5, "interview_type": 1}] end))

      expect(Interview.is_signup_lesser_than(interview.id, 2)) |> to(be_false)
    end

    it "should return false when signups are equal to max" do
      interview = create(:interview)
      allow Repo |> to(accept(:all, fn(_) -> [%{"interview_id": interview.id, "signup_count": 5, "interview_type": 1}] end))

      expect(Interview.is_signup_lesser_than(interview.id, 2)) |> to(be_false)
    end
  end

  describe "has_panelist_not_interviewed_candidate" do
    it "should return true when panelist has not interviewed current candidate" do
      interview = build(:interview)

      expect(Interview.has_panelist_not_interviewed_candidate(interview, [])) |> to(be_true)
    end

    it "should return false when panelist has interviewed current candidate" do
      interview = build(:interview)
      candidates_interviewed = [interview.candidate_id]

      expect(Interview.has_panelist_not_interviewed_candidate(interview, candidates_interviewed)) |> to(be_false)
    end
  end

  describe "update_status" do
    it "should not update interview when status is already entered" do
      interview = create(:interview)
      interview_status = create(:interview_status)
      Interview.update_status(interview.id, interview_status.id)

      update = fn ->  Interview.update_status(interview.id, 0) end

      expected_error = {:changeset_error, [%JSONErrorReason{field_name: :interview_status, reason: "Feedback has already been entered"}]}
      expect update |> to(throw_term expected_error)
    end

    it "should not update interview when status is invalid" do
      interview = create(:interview)
      update = fn ->  Interview.update_status(interview.id, 0) end
      expected_error = {:error, [%JSONErrorReason{field_name: :interview_status, reason: "does not exist"}]}

      expect update |> to(throw_term expected_error)
    end

    it "should update status and not delete other interviews,panelists for a candidate when status is not Pass" do
      interview = create(:interview)
      interview_status = create(:interview_status)
      interview_to_be_retained = create(:interview, candidate_id: interview.candidate_id, candidate: interview.candidate, start_time: Date.now |> Date.shift(days: 7))
      panelists_to_be_retained = create(:interview_panelist, interview_id: interview_to_be_retained.id)

      Interview.update_status(interview.id, interview_status.id)

      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(!is_nil(Interview |> Repo.get(interview_to_be_retained.id))) |> to(be_true)
      expect(!is_nil(InterviewPanelist |> Repo.get(panelists_to_be_retained.id))) |> to(be_true)
    end

    it "should update status and delete future interviews,panelists when status is Pass" do
      Repo.delete_all InterviewStatus

      future_date = Date.now |> Date.shift(days: 7)
      interview = create(:interview, start_time: Date.now)
      future_interview = create(:interview, candidate_id: interview.candidate_id, candidate: interview.candidate, start_time: future_date)
      future_panelist = create(:interview_panelist, interview_id: future_interview.id)
      interview_status = create(:interview_status, name: "Pass")

      Interview.update_status(interview.id, interview_status.id)

      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(Interview |> Repo.get(future_interview.id)) |> to(be_nil)
      expect(InterviewPanelist |> Repo.get(future_panelist.id)) |> to(be_nil)
    end

    it "should update status and not delete past interviews,panelists when status is Pass" do
      Repo.delete_all InterviewStatus

      past_date = Date.now |> Date.shift(days: -7)
      interview = create(:interview, start_time: Date.now)
      interview_to_be_retained = create(:interview, candidate_id: interview.candidate_id, candidate: interview.candidate, start_time: past_date)
      panelists_to_be_retained = create(:interview_panelist, interview_id: interview_to_be_retained.id)
      interview_status = create(:interview_status, name: "Pass")

      Interview.update_status(interview.id, interview_status.id)

      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
      expect(!is_nil(Interview |> Repo.get(interview_to_be_retained.id))) |> to(be_true)
      expect(!is_nil(InterviewPanelist |> Repo.get(panelists_to_be_retained.id))) |> to(be_true)
    end

    it "should update status when status is Pass and there are no successive rounds" do
      Repo.delete_all InterviewStatus

      interview = create(:interview)
      interview_status = create(:interview_status, name: "Pass")

      Interview.update_status(interview.id, interview_status.id)

      updated_interview = Interview |> Repo.get(interview.id)
      expect(updated_interview.interview_status_id) |> to(be(interview_status.id))
    end
  end

  describe "validation for updating the interview schedule" do
    let :now, do: Date.now()
    let :candidate, do: create(:candidate)
    let :code_pairing_interview_type, do: create(:interview_type, priority: 1, name: "CP")
    let :technical_one_interview_type, do: create(:interview_type, priority: 2, name: "T1")
    let :technical_two_interview_type, do: create(:interview_type, priority: 3, name: "T2")

    it "should not allow interview with less priority to happen before interview with high priority" do
      code_pairing = create(:interview, interview_type: code_pairing_interview_type, interview_type_id: code_pairing_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now)
      create(:interview, interview_type: technical_one_interview_type, interview_type_id: technical_one_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now |> Date.shift(hours: 2))

      changeset = Interview.changeset(code_pairing, %{"start_time" => now |> Date.shift(hours: 1.01)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be("should be before T1 atleast by 1 hour"))
    end

    it "should not allow interview with high priority to happen after interview with low priority" do
      create(:interview, interview_type: code_pairing_interview_type, interview_type_id: code_pairing_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now)
      technical_one = create(:interview, interview_type: technical_one_interview_type, interview_type_id: technical_one_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now
      |> Date.shift(hours: 2))

      changeset = Interview.changeset(technical_one, %{"start_time" => now |> Date.shift(hours: -1.01)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be("should be after CP atleast by 1 hour"))
    end

    it "should not allow interview to be scheduled after interview with high priority and before interview with low priority" do
      create(:interview, interview_type: code_pairing_interview_type, interview_type_id: code_pairing_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now)
      technical_one = create(:interview, interview_type: technical_one_interview_type, interview_type_id: technical_one_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now |> Date.shift(hours: 1))
      create(:interview, interview_type: technical_two_interview_type, interview_type_id: technical_two_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now
      |> Date.shift(hours: 1.5))

      changeset = Interview.changeset(technical_one, %{"start_time" => now |> Date.shift(hours: 0.75)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be("should be after CP and before T2 atleast by 1 hour"))
    end

    it "should allow interview with high priority to happen after interview with low priority" do
      create(:interview, interview_type: code_pairing_interview_type, interview_type_id: code_pairing_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now)
      technical_one = create(:interview, interview_type: technical_one_interview_type, interview_type_id: technical_one_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now
      |> Date.shift(hours: 2))

      changeset = Interview.changeset(technical_one, %{"start_time" => now |> Date.shift(days: 2)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be(nil))
    end

    it "should allow interview with low priority to happen before interview with high priority" do
      code_pairing = create(:interview, interview_type: code_pairing_interview_type, interview_type_id: code_pairing_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now)
      create(:interview, interview_type: technical_one_interview_type, interview_type_id: technical_one_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now
      |> Date.shift(hours: 4))

      changeset = Interview.changeset(code_pairing, %{"start_time" => now |> Date.shift(hours: -2)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be(nil))
    end

    it "should allow interview with lowest priority to be modified without any constraint" do
      code_pairing = create(:interview, interview_type: code_pairing_interview_type, interview_type_id: code_pairing_interview_type.id, candidate: candidate, candidate_id: candidate.id, start_time: now)

      changeset = Interview.changeset(code_pairing, %{"start_time" => now |> Date.shift(hours: -2)})
      changeset = Interview.validate_with_other_rounds(changeset)

      expect changeset.errors[:start_time] |> to(be(nil))
    end

  end
end
