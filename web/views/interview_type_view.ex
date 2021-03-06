defmodule RecruitxBackend.InterviewTypeView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.InterviewTypeView

  def render("index.json", %{interview_types: interview_types}) do
    render_many(interview_types, InterviewTypeView, "interview_type.json")
  end

  def render("interview_type.json", %{interview_type: interview_type}) do
    %{
      id: interview_type.id,
      name: interview_type.name,
      priority: interview_type.priority
    }
  end

  def render("interview_type_without_id.json", %{interview_type: interview_type}) do
    %{
      name: interview_type.name
    }
  end
end
