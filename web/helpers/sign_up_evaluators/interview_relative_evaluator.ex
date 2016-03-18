defmodule RecruitxBackend.InterviewRelativeEvaluator do

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.SignUpEvaluationStatus
  alias Timex.Date

  @time_buffer_between_sign_ups 2

  def evaluate(sign_up_evaluation_status, sign_up_data_container, interview) do
    sign_up_evaluation_status
    |> has_not_interviewed_candidate(sign_up_data_container.candidate_ids_interviewed, interview)
    |> has_no_other_interview_within_time_buffer(sign_up_data_container.my_previous_sign_up_start_times, interview)
    |> is_interview_not_over(interview)
    |> is_signup_count_lesser_than_max(sign_up_data_container.signup_counts, interview.id)
  end

  defp has_not_interviewed_candidate(sign_up_evaluation_status, candidate_ids_interviewed, interview) do
    if sign_up_evaluation_status.valid? and !has_panelist_not_interviewed_candidate(interview, candidate_ids_interviewed) do
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You have already signed up an interview for this candidate"})
    end
    sign_up_evaluation_status
  end

  defp has_no_other_interview_within_time_buffer(sign_up_evaluation_status, my_previous_sign_up_start_times, interview) do
    if sign_up_evaluation_status.valid? and !is_within_time_buffer_of_my_previous_sign_ups(interview, my_previous_sign_up_start_times) do
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are already signed up for another interview within #{@time_buffer_between_sign_ups} hours"})
    end
    sign_up_evaluation_status
  end

  defp is_interview_not_over(sign_up_evaluation_status, interview) do
    if sign_up_evaluation_status.valid? and !Interview.is_not_completed(interview) do
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "Interview is already over!"})
    end
    sign_up_evaluation_status
  end

  defp is_signup_count_lesser_than_max(sign_up_evaluation_status, signup_counts, interview_id) do
    if sign_up_evaluation_status.valid? and !is_signup_lesser_than_max_count(interview_id, signup_counts) do
      sign_up_evaluation_status = sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup_count, "More than #{InterviewPanelist.max_count} signups are not allowed"})
    end
    sign_up_evaluation_status
  end

  defp is_within_time_buffer_of_my_previous_sign_ups(model, my_sign_up_start_times) do
    Enum.all?(my_sign_up_start_times, fn(sign_up_start_time) ->
      abs(Date.diff(model.start_time, sign_up_start_time, :hours)) >= @time_buffer_between_sign_ups
    end)
  end

  defp has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed) do
    !Enum.member?(candidate_ids_interviewed, model.candidate_id)
  end

  defp is_signup_lesser_than_max_count(model_id, signup_counts) do
    result = Enum.filter(signup_counts, fn(i) -> i.interview_id == model_id end)
    result == [] or List.first(result).signup_count < InterviewPanelist.max_count
  end
end
