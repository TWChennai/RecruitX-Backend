defmodule RecruitxBackend.RoleInterviewTypeView do
  use RecruitxBackend.Web, :view

  def render("role_interview_type.json", %{role_interview_type: role_interview_type}) do
    %{
      id: role_interview_type.interview_type_id
    }
  end
end
