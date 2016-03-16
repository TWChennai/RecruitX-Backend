defmodule RecruitxBackend.InterviewRelativeEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewRelativeEvaluator

  alias RecruitxBackend.InterviewRelativeEvaluator
  alias Timex.Date

  describe "is_signup_lesser_than" do
    it "should return true when there are no signups" do
      interview = create(:interview)

      expect(InterviewRelativeEvaluator.is_signup_lesser_than_max_count(interview.id, [])) |> to(be_true)
    end

    it "should return true when signups are lesser than max" do
      interview = create(:interview)
      signup_counts = [%{"interview_id": interview.id, "signup_count": 1, "interview_type": 1}]
      expect(InterviewRelativeEvaluator.is_signup_lesser_than_max_count(interview.id, signup_counts)) |> to(be_true)
    end

    it "should return false when signups are greater than max" do
      interview = create(:interview)
      signup_counts = [%{"interview_id": interview.id, "signup_count": 5, "interview_type": 1}]
      expect(InterviewRelativeEvaluator.is_signup_lesser_than_max_count(interview.id, signup_counts)) |> to(be_false)
    end

    it "should return false when signups are equal to max" do
      interview = create(:interview)
      signup_counts = [%{"interview_id": interview.id, "signup_count": 5, "interview_type": 1}]
      expect(InterviewRelativeEvaluator.is_signup_lesser_than_max_count(interview.id, signup_counts)) |> to(be_false)
    end
  end

  describe "has_panelist_not_interviewed_candidate" do
    it "should return true when panelist has not interviewed current candidate" do
      interview = build(:interview)

      expect(InterviewRelativeEvaluator.has_panelist_not_interviewed_candidate(interview, [])) |> to(be_true)
    end

    it "should return false when panelist has interviewed current candidate" do
      interview = build(:interview)
      candidates_interviewed = [interview.candidate_id]

      expect(InterviewRelativeEvaluator.has_panelist_not_interviewed_candidate(interview, candidates_interviewed)) |> to(be_false)
    end
  end

  describe "is_within_time_buffer_of_my_previous_sign_ups" do
    it "should return false if current interview is within 2 hours of signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = [interview.start_time |> Date.shift(hours: 1)]
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end

    it "should return false if current interview is within 2 hours of signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = [interview.start_time |> Date.shift(hours: -1)]
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end

    it "should return true if there are no signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = []
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end

    it "should return true if current interview is exactly 2 hours earlier to signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = [interview.start_time |> Date.shift(hours: 2)]
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end

    it "should return true if interview is exactly 2 hours later to signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = [interview.start_time |> Date.shift(hours: -2)]
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end

    it "should return true if current interview is more than 2 hours earlier to signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = [interview.start_time |> Date.shift(hours: 3)]
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end

    it "should return true if interview is more than 2 hours later to signed up interviews" do
      interview = create(:interview)
      my_sign_up_start_times = [interview.start_time |> Date.shift(hours: -3)]
      InterviewRelativeEvaluator.is_within_time_buffer_of_my_previous_sign_ups(interview, my_sign_up_start_times)
    end
  end
end
