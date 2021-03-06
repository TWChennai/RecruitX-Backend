defmodule RecruitxBackend.InterviewView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.CandidateView
  alias RecruitxBackend.FeedbackImageView
  alias RecruitxBackend.InterviewPanelistView
  alias RecruitxBackend.InterviewTypeView
  alias RecruitxBackend.InterviewView
  alias RecruitxBackend.TimexHelper

  def render("index.json", %{interviews_with_signup: interviews}) do
    render_many(interviews, InterviewView, "interview_with_signup.json")
  end

  def render("interviews_preload.json", %{interviews_with_signup: interviews}) do
    render_many(interviews, InterviewView, "interview_with_signup_preload.json")
  end

  def render("index.json", %{interviews_for_candidate: interviews}) do
    render_many(interviews, InterviewView, "interviews_for_candidate.json")
  end

  def render("index.json", %{interviews: interviews}) do
    %{
      total_pages: interviews.total_pages,
      interviews:  render_many(interviews.entries, InterviewView, "interview.json")
    }
  end

  def render("show.json", %{interview: interview}) do
    render_one(interview, InterviewView, "interview_with_panelists.json")
  end

  def render("success.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: format_datetime(interview.start_time),
      candidate_id: interview.candidate_id,
      interview_type_id: interview.interview_type_id
    }
  end

  def render("interview_with_signup.json", %{interview: %{candidate: _} = interview}) do
    %{
      id: interview.id,
      start_time: format_datetime(interview.start_time),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      signup: interview.signup,
      signup_error: interview.signup_error,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_with_signup_preload.json", %{interview: %{candidate: _} = interview}) do
    %{
      id: interview.id,
      start_time: format_datetime(interview.start_time),
      interview_type_id: render_one(interview.interview_type, InterviewTypeView, "interview_type.json"),
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills_preload.json"),
      signup: interview.signup,
      signup_error: interview.signup_error,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_with_signup.json", %{interview: slot}) do
    %{
      id: slot.id,
      status_id: nil,
      start_time: format_datetime(slot.start_time),
      interview_type_id: slot.interview_type_id,
      candidate: render_one(slot, CandidateView, "dummy_candidate.json"),
      signup: slot.signup,
      signup_error: slot.signup_error,
      panelists: render_many(slot.slot_panelists, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_with_signup_preload.json", %{interview: slot}) do
    %{
      id: slot.id,
      status_id: nil,
      start_time: format_datetime(slot.start_time),
      interview_type_id: render_one(slot.interview_type, InterviewTypeView, "interview_type.json"),
      candidate: render_one(slot, CandidateView, "dummy_candidate_preload.json"),
      signup: slot.signup,
      signup_error: slot.signup_error,
      panelists: render_many(slot.slot_panelists, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview.json", %{interview: %{candidate: _} = interview}) do
    %{
      id: interview.id,
      start_time: format_datetime(interview.start_time),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      last_interview_status: interview.last_interview_status,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview.json", %{interview: slot}) do
    %{
      id: slot.id,
      start_time: format_datetime(slot.start_time),
      interview_type_id: slot.interview_type_id,
      candidate: render_one(slot, CandidateView, "dummy_candidate.json"),
      status_id: nil,
      last_interview_status: nil,
      panelists: render_many(slot.slot_panelists, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interviews_for_candidate.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: format_datetime(interview.start_time),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_with_panelists.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: format_datetime(interview.start_time),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json"),
      feedback_images: render_many(interview.feedback_images, FeedbackImageView, "feedback_image.json"),
      previous_interview_status: interview.previous_interview_status
    }
  end

  defp format_datetime(datetime), do: TimexHelper.format(datetime, "%Y-%m-%dT%H:%M:%SZ")
end
