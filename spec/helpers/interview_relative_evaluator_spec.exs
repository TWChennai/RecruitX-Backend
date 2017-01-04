defmodule RecruitxBackend.InterviewRelativeEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewRelativeEvaluator

  alias Decimal
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewRelativeEvaluator
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.SignUpEvaluator
  alias RecruitxBackend.TimexHelper

  let :role, do: insert(:role)

  describe "has_not_interviewed_candidate" do
    it "should be invalid when panelist has already done a previous interview for the candidate" do
      candidate = insert(:candidate)
      interview1 = insert(:interview, candidate: candidate)
      interview2 = insert(:interview, candidate: candidate)

      insert(:interview_panelist, interview: interview1, panelist_login_name: "test")
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container("test", Decimal.new(1), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview2)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "You have already signed up an interview for this candidate"]))
    end

    it "should be invalid when panelist has already signed up for the same interview" do
      candidate = insert(:candidate)
      interview1 = insert(:interview, candidate: candidate)
      insert(:interview_panelist, interview: interview1, panelist_login_name: "test")
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container("test", Decimal.new(1), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview1)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "You have already signed up an interview for this candidate"]))
    end

    it "should be valid when panelist has not interviewed current candidate" do
      interview = insert(:interview)
      interview_panelist = params_with_assocs(:interview_panelist)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(1), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(errors) |> to(be([]))
      expect(validity) |> to(be_true())
    end
  end

  describe "is_interview_not_over" do
    it "should be invalid when feedback is already entered" do
      interview = insert(:interview, interview_status: build(:interview_status))
      interview_panelist = params_with_assocs(:interview_panelist, interview: interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "Interview is already over!"]))
    end
  end

  describe "is_signup_count_lesser_than_max" do
    it "should be invalid when signups equal to max are already done" do
      interview = insert(:interview)
      insert(:interview_panelist, interview: interview)
      insert(:interview_panelist, interview: interview)
      interview_panelist = params_with_assocs(:interview_panelist, interview: interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup_count: "More than 2 signups are not allowed"]))
    end

    it "should be valid when signups are less than max" do
      interview = insert(:interview)
      insert(:interview_panelist, interview: interview)
      interview_panelist = params_with_assocs(:interview_panelist, interview: interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should be valid when there are no signups" do
      interview = insert(:interview)
      interview_panelist = params_with_assocs(:interview_panelist, interview: interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end
  end

  describe "is_tech1_got_sign_up" do
    let :now, do: TimexHelper.utc_now()

    it "should be valid if current interview round is not Tech2" do
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech1_interview = insert(:interview, interview_type: tech1_round)
      interview_panelist = params_with_assocs(:interview_panelist, interview: tech1_interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, tech1_interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should be invalid if current interview round Tech2 and Tech1 didn't get signups" do
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech2_round = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = insert(:candidate)
      insert(:interview, candidate: candidate, interview_type: tech1_round)
      tech2_interview = insert(:interview, candidate: candidate, interview_type: tech2_round)
      interview_panelist = params_with_assocs(:interview_panelist, interview: tech2_interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, tech2_interview)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "Please signup for Tech1 round as signup is pending for that"]))
    end

    it "should be valid if current interview round Tech2 and Tech1 got enough signups" do
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech2_round = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = insert(:candidate)
      tech1_interview = insert(:interview, candidate: candidate, interview_type: tech1_round)
      tech2_interview = insert(:interview, candidate: candidate, interview_type: tech2_round)
      insert(:interview_panelist, interview: tech1_interview)
      insert(:interview_panelist, interview: tech1_interview)
      interview_panelist = params_with_assocs(:interview_panelist, interview: tech2_interview)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, tech2_interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should be valid if current slot is Tech2 and Tech1 got enough signups" do
      Repo.delete_all(Interview)
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech2_round = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = insert(:candidate)
      start_time = now() |> TimexHelper.add(2, :hours)
      end_time = start_time |> TimexHelper.add(1, :hours)
      tech1_interview = insert(:interview, candidate: candidate, interview_type: tech1_round,
                        start_time: start_time, end_time: end_time)
      tech2_slot = insert(:slot, interview_type: tech2_round, start_time: now() |> TimexHelper.add(4, :hours))
      insert(:interview_panelist, interview: tech1_interview)
      insert(:interview_panelist, interview: tech1_interview)
      slot_panelist = params_for(:slot_panelist, slot_id: tech2_slot.id)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(slot_panelist.panelist_login_name, Decimal.new(2), role(), true)

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, tech2_slot)
      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should be not valid if current slot is Tech2 and Tech1 haven't got enough signups" do
      tech1_round = InterviewType.retrieve_by_name(InterviewType.technical_1)
      tech2_round = InterviewType.retrieve_by_name(InterviewType.technical_2)
      candidate = insert(:candidate)
      start_time = now() |> TimexHelper.add(2, :hours)
      end_time = start_time |> TimexHelper.add(1, :hours)
      tech1_interview = insert(:interview, candidate: candidate, interview_type: tech1_round,
                        start_time: start_time, end_time: end_time)
      tech1_interview2 = insert(:interview, interview_type: tech1_round,
                        start_time: start_time, end_time: end_time)
      tech2_slot = insert(:slot, interview_type: tech2_round, start_time: now() |> TimexHelper.add(4, :hours))
      insert(:interview_panelist, interview: tech1_interview)
      insert(:interview_panelist, interview: tech1_interview2)
      insert(:interview_panelist, interview: tech1_interview2)
      slot_panelist = params_with_assocs(:interview_panelist, interview: tech2_slot)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(slot_panelist.panelist_login_name, Decimal.new(2), role(), true)

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, tech2_slot)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "Please signup for Tech1 round as signup is pending for that"]))
    end
  end

  describe "has_no_other_interview_within_time_buffer" do
    it "should not allow panelist to sign up if he has another interview within time buffer of 2 hours" do
      interview_signed_up = insert(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = insert(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(1, :hours))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(1), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "You are already signed up for another interview within 2 hours"]))
    end

    it "should not allow panelist to sign up if he has another interview within time buffer of 2 hours" do
      interview_signed_up = insert(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = insert(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(-1, :hours))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(1), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_false())
      expect(errors) |> to(be([signup: "You are already signed up for another interview within 2 hours"]))
    end

    it "should allow panelist to sign up if he has other interviews beyond time buffer of 2 hours later" do
      interview_signed_up = insert(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = insert(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(3, :hours))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should allow panelist to sign up if he has other interviews beyond time buffer of 2 hours before" do
      interview_signed_up = insert(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = insert(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(-3, :hours))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should allow panelist to sign up if he has other interviews at exactly time buffer of 2 hours later" do
      interview_signed_up = insert(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = insert(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(2, :hours))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end

    it "should allow panelist to sign up if he has other interviews at exactly time buffer of 2 hours before" do
      interview_signed_up = insert(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = insert(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(-2, :hours))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2), role())

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true())
      expect(errors) |> to(be([]))
    end
  end
end
