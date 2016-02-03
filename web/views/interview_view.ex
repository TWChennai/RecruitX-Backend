defmodule RecruitxBackend.InterviewView do
  use RecruitxBackend.Web, :view

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

  def render("interview.json", %{interview: interview}) do
    %{
      id: interview.id,
      start_time: interview.start_time,
      candidate: render_one(interview.candidate, RecruitxBackend.CandidateView, "candidate.json"),
      interview_type: render_one(interview.interview_type, RecruitxBackend.InterviewTypeView, "interview_type_without_id.json"),
      sign_up: interview.signup
    }
  end
end
