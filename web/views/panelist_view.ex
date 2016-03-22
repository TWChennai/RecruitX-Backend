defmodule RecruitxBackend.PanelistView do
  use RecruitxBackend.Web, :view

  def render("panelist.json", %{panelist: panelist}) do
    %{
      interview_id: panelist.interview_id,
      name: panelist.panelist_login_name
    }
  end
end
