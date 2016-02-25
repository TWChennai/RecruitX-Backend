defmodule RecruitxBackend.InterviewStatusView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.InterviewStatusView

  def render("index.json", %{interview_status: interview_status}) do
    render_many(interview_status, InterviewStatusView, "interview_status.json")
  end

  def render("interview_status.json", %{interview_status: interview_status}) do
    %{
      id: interview_status.id,
      name: interview_status.name
    }
  end
end
