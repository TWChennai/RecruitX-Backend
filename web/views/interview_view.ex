defmodule RecruitxBackend.InterviewView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{interviews_with_signup: interviews}) do
    render_many(interviews, RecruitxBackend.InterviewView, "interview_with_signup.json")
  end

  def render("index.json", %{interviews: interviews}) do
    render_many(interviews, RecruitxBackend.InterviewView, "interview.json")
  end

  def render("show.json", %{interview: interview}) do
    render_one(interview, RecruitxBackend.InterviewView, "interview.json")
  end

  def render("missing_param_error.json", %{param: param}) do
    %{
      field: param,
      reason: "missing/empty required parameter"
    }
  end

  def render("interview_with_signup.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: interview.start_time,
      candidate: render_one(interview.candidate, RecruitxBackend.CandidateView, "candidate.json"),
      signup: interview.signup
    }
  end

  def render("interview.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: interview.start_time,
      candidate: render_one(interview.candidate, RecruitxBackend.CandidateView, "candidate.json")
    }
  end
end
