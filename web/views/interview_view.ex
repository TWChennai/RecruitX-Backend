defmodule RecruitxBackend.InterviewView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.CandidateView
  alias RecruitxBackend.FeedbackImageView
  alias RecruitxBackend.InterviewPanelistView
  alias RecruitxBackend.InterviewView
  alias Timex.DateFormat

  def render("index.html", %{interviews_with_signup: interviews, all: all, not_login: not_login}) do
    render_many(interviews, InterviewView, "all_interview_slot.html", all: all, not_login: not_login)
  end

  def render("index.html", %{interviews_with_signup: interviews, not_login: not_login}) do
    render_many(interviews, InterviewView, "interview_slot.html", not_login: not_login)
  end

  def render("index.json", %{interviews_with_signup: interviews}) do
    render_many(interviews, InterviewView, "interview_with_signup.json")
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
      start_time: DateFormat.format!(interview.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      candidate_id: interview.candidate_id,
      interview_type_id: interview.interview_type_id
    }
  end

  def render("interview_with_signup.json", %{interview: %{candidate: _} = interview}) do
    %{
      id: interview.id,
      start_time: DateFormat.format!(interview.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      signup: interview.signup,
      signup_error: interview.signup_error,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_with_signup.json", %{interview: slot}) do
    %{
      id: slot.id,
      status_id: nil,
      start_time: DateFormat.format!(slot.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      interview_type_id: slot.interview_type_id,
      candidate: render_one(slot, CandidateView, "dummy_candidate.json"),
      signup: slot.signup,
      signup_error: slot.signup_error,
      panelists: render_many(slot.slot_panelists, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_slot.html", %{interview: %{candidate: _} = interview, not_login: not_login}) do
    render "interview.html", interview: interview , not_login: not_login
  end

  def render("interview_slot.html", %{interview: slot, not_login: not_login}) do
    render "slot.html", slot: slot, not_login: not_login
  end

  def render("all_interview_slot.html", %{interview: %{candidate: _} = interview, all: all, not_login: not_login}) do
    render "all_interview.html", interview: interview , all: all, not_login: not_login
  end

  def render("all_interview_slot.html", %{interview: slot, all: all, not_login: not_login}) do
    render "all_slot.html", slot: slot, all: all, not_login: not_login
  end

  def render("interview.json", %{interview: %{candidate: _} = interview}) do
    %{
      id: interview.id,
      start_time: DateFormat.format!(interview.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
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
      start_time: DateFormat.format!(slot.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
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
      start_time: DateFormat.format!(interview.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json")
    }
  end

  def render("interview_with_panelists.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: DateFormat.format!(interview.start_time, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      interview_type_id: interview.interview_type_id,
      candidate: render_one(interview.candidate, CandidateView, "candidate_with_skills.json"),
      status_id: interview.interview_status_id,
      panelists: render_many(interview.interview_panelist, InterviewPanelistView, "interview_panelist.json"),
      feedback_images: render_many(interview.feedback_images, FeedbackImageView, "feedback_image.json"),
      previous_interview_status: interview.previous_interview_status
    }
  end
end
