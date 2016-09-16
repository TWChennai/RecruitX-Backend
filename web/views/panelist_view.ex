defmodule RecruitxBackend.PanelistView do
  use RecruitxBackend.Web, :view

  def render("panelist.json", %{interview_panelist: interview_panelist}) do
    %{
      interview_id: interview_panelist.interview_id,
      name: interview_panelist.panelist_login_name
    }
  end

  def render("panelist_web.json", %{interview_panelist: interview_panelist}) do
    %{
      interview_id: interview_panelist.interview_id,
      name: interview_panelist.name
    }
  end

  def render("panelist.json", %{slot_panelist: slot_panelist}) do
    %{
      slot_id: slot_panelist.slot_id,
      name: slot_panelist.panelist_login_name
    }
  end
end
