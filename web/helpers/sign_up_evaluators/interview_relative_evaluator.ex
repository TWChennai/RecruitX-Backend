defmodule RecruitxBackend.InterviewRelativeEvaluator do
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.TimexHelper

  @time_buffer_between_sign_ups 2
  @tech2_interview_type_id 5

  def evaluate(sign_up_evaluation_status, sign_up_data_container, interview) do
    sign_up_evaluation_status
    |> has_not_interviewed_candidate(sign_up_data_container.candidate_ids_interviewed, interview, sign_up_data_container.slot)
    |> has_no_other_interview_within_time_buffer(sign_up_data_container.my_previous_sign_up_start_times, interview)
    |> is_interview_not_over(interview, sign_up_data_container.slot)
    |> is_signup_count_lesser_than_max(sign_up_data_container.signup_counts, sign_up_data_container.interview_type_based_sign_up_limits, interview, sign_up_data_container.slot)
    |> is_tech1_got_enough_sign_up(interview)
  end

  defp is_tech1_got_enough_sign_up(sign_up_evaluation_status, %{interview_type_id: @tech2_interview_type_id, candidate_id: candidate_id} = interview) do
    technical_one = InterviewType.retrieve_by_name(InterviewType.technical_1)
    case Interview.get_previous_round(candidate_id, interview.interview_type_id) do
      [] -> sign_up_evaluation_status
      [previous_interview] -> previous_interview_signup_count = InterviewPanelist.get_signup_count_for_interview_id(previous_interview.id) |> Repo.one
                              case previous_interview_signup_count != technical_one.max_sign_up_limit do
                                true -> sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "Please signup for Tech1 round as signup is pending for that"})
                                false -> sign_up_evaluation_status
                              end
    end
  end

  defp is_tech1_got_enough_sign_up(sign_up_evaluation_status, %{interview_type_id: @tech2_interview_type_id} = slot) do
    technical_one = InterviewType.retrieve_by_name(InterviewType.technical_1)
    is_any_tech_one_not_satisfied =
        Interview.tech_one_interview_ids_between(TimexHelper.utc_now(), slot.start_time)
          |> Enum.any?(fn tech_one_interview_id ->
            InterviewPanelist.get_signup_count_for_interview_id(tech_one_interview_id)
              |> Repo.one != technical_one.max_sign_up_limit end)
    case is_any_tech_one_not_satisfied do
      true -> sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "Please signup for Tech1 round as signup is pending for that"})
      false -> sign_up_evaluation_status
    end
  end

  defp is_tech1_got_enough_sign_up(sign_up_evaluation_status, _not_tech2_interview), do: sign_up_evaluation_status

  defp has_not_interviewed_candidate(%{valid?: false} = sign_up_evaluation_status, _, _, _), do: sign_up_evaluation_status
  defp has_not_interviewed_candidate(sign_up_evaluation_status, _, _, true), do: sign_up_evaluation_status
  defp has_not_interviewed_candidate(sign_up_evaluation_status, candidate_ids_interviewed, interview, false) do
    if !has_panelist_not_interviewed_candidate(interview, candidate_ids_interviewed) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You have already signed up an interview for this candidate"})
    else
      sign_up_evaluation_status
    end
  end

  defp has_no_other_interview_within_time_buffer(%{valid?: false} = sign_up_evaluation_status, _, _), do: sign_up_evaluation_status
  defp has_no_other_interview_within_time_buffer(sign_up_evaluation_status, my_previous_sign_up_start_times, interview) do
    if !is_within_time_buffer_of_my_previous_sign_ups(interview, my_previous_sign_up_start_times) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "You are already signed up for another interview within #{@time_buffer_between_sign_ups} hours"})
    else
      sign_up_evaluation_status
    end
  end

  defp is_interview_not_over(%{valid?: false} = sign_up_evaluation_status, _, _), do: sign_up_evaluation_status
  defp is_interview_not_over(sign_up_evaluation_status, _, true), do: sign_up_evaluation_status
  defp is_interview_not_over(sign_up_evaluation_status, interview, false) do
    if !Interview.is_not_completed(interview) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup, "Interview is already over!"})
    else
      sign_up_evaluation_status
    end
  end

  defp is_signup_count_lesser_than_max(%{valid?: false} = sign_up_evaluation_status, _, _, _, _), do: sign_up_evaluation_status
  defp is_signup_count_lesser_than_max(sign_up_evaluation_status, signup_counts, interview_type_based_sign_up_limits, interview, is_slot) do
    max_sign_up_limit = Enum.find_value(interview_type_based_sign_up_limits, 0, fn({interview_type_id, max_sign_up_limit}) -> interview_type_id == interview.interview_type_id && max_sign_up_limit end)
    if !is_signup_lesser_than_max_count(interview.id, signup_counts, max_sign_up_limit, is_slot) do
      sign_up_evaluation_status |> SignUpEvaluationStatus.add_errors({:signup_count, "More than #{max_sign_up_limit} signups are not allowed"})
    else
      sign_up_evaluation_status
    end
  end

  defp is_within_time_buffer_of_my_previous_sign_ups(model, my_sign_up_start_times) do
    Enum.all?(my_sign_up_start_times, fn(sign_up_start_time) ->
      abs(Timex.diff(model.start_time, sign_up_start_time, :hours)) >= @time_buffer_between_sign_ups
    end)
  end

  defp has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed) do
    !Enum.member?(candidate_ids_interviewed, model.candidate_id)
  end

  defp is_signup_lesser_than_max_count(model_id, signup_counts, max_sign_up_limit, false) do
    signup_count = Enum.find_value(signup_counts, 0, fn(i) -> i.interview_id == model_id && i.signup_count end)
    signup_count < max_sign_up_limit
  end

  defp is_signup_lesser_than_max_count(model_id, signup_counts, max_sign_up_limit, true) do
    signup_count = Enum.find_value(signup_counts, 0, fn(i) -> i.slot_id == model_id && i.signup_count end)
    signup_count < max_sign_up_limit
  end
end
