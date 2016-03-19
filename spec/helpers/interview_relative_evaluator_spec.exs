defmodule RecruitxBackend.InterviewRelativeEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewRelativeEvaluator

  alias Decimal
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewRelativeEvaluator
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.SignUpEvaluator
  alias Timex.Date

  describe "has_not_interviewed_candidate" do
    it "should be invalid when panelist has already done a previous interview for the candidate" do
      candidate = create(:candidate)
      interview1 = create(:interview, candidate_id: candidate.id)
      interview2 = create(:interview, candidate_id: candidate.id)

      create(:interview_panelist, interview_id: interview1.id, panelist_login_name: "test")
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container("test", Decimal.new(1))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview2)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "You have already signed up an interview for this candidate"]))
    end

    it "should be invalid when panelist has already signed up for the same interview" do
      candidate = create(:candidate)
      interview1 = create(:interview, candidate_id: candidate.id)
      create(:interview_panelist, interview_id: interview1.id, panelist_login_name: "test")
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container("test", Decimal.new(1))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview1)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "You have already signed up an interview for this candidate"]))
    end

    it "should be valid when panelist has not interviewed current candidate" do
      interview = create(:interview)
      interview_panelist = fields_for(:interview_panelist)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(1))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(errors) |> to(be([]))
      expect(validity) |> to(be_true)
    end
  end

  describe "is_interview_not_over" do
    it "should be invalid when feedback is already entered" do
      interview = create(:interview, interview_status_id: create(:interview_status).id)
      interview_panelist = fields_for(:interview_panelist, interview_id: interview.id)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "Interview is already over!"]))
    end
  end

  describe "is_signup_count_lesser_than_max" do
    it "should be invalid when signups equal to max are already done" do
      interview = create(:interview)
      create(:interview_panelist, interview_id: interview.id)
      create(:interview_panelist, interview_id: interview.id)
      interview_panelist = fields_for(:interview_panelist, interview_id: interview.id)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup_count: "More than 2 signups are not allowed"]))
    end

    it "should be valid when signups are less than max" do
      interview = create(:interview)
      create(:interview_panelist, interview_id: interview.id)
      interview_panelist = fields_for(:interview_panelist, interview_id: interview.id)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end

    it "should be valid when there are no signups" do
      interview = create(:interview)
      interview_panelist = fields_for(:interview_panelist, interview_id: interview.id)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_panelist.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end
  end

  describe "has_no_other_interview_within_time_buffer" do
    it "should not allow panelist to sign up if he has another interview within time buffer of 2 hours" do
      interview_signed_up = create(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> Date.shift(hours: 1))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(1))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "You are already signed up for another interview within 2 hours"]))
    end

    it "should not allow panelist to sign up if he has another interview within time buffer of 2 hours" do
      interview_signed_up = create(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> Date.shift(hours: -1))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(1))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "You are already signed up for another interview within 2 hours"]))
    end

    it "should allow panelist to sign up if he has other interviews beyond time buffer of 2 hours later" do
      interview_signed_up = create(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> Date.shift(hours: 3))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end

    it "should allow panelist to sign up if he has other interviews beyond time buffer of 2 hours before" do
      interview_signed_up = create(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> Date.shift(hours: -3))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end

    it "should allow panelist to sign up if he has other interviews at exactly time buffer of 2 hours later" do
      interview_signed_up = create(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> Date.shift(hours: 2))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end

    it "should allow panelist to sign up if he has other interviews at exactly time buffer of 2 hours before" do
      interview_signed_up = create(:interview_panelist)
      signed_up_interview = Interview |> Repo.get(interview_signed_up.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> Date.shift(hours: -2))
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(interview_signed_up.panelist_login_name, Decimal.new(2))

      %{valid?: validity, errors: errors} = InterviewRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, sign_up_data_container, new_interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end
  end
end