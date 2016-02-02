defmodule RecruitxBackend.InterviewTypeView do
  use RecruitxBackend.Web, :view

 def render("interview_type_without_id.json", %{interview_type: interview_type}) do
    %{
      name: interview_type.name
    }
  end
end
