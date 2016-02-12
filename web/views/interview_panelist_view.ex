defmodule RecruitxBackend.InterviewPanelistView do
  use RecruitxBackend.Web, :view

  def render("interview_panelist.json", %{interview_panelist: interview_panelist}) do
    %{
      name: interview_panelist.panelist_login_name
    }
  end
end
