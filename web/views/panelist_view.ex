defmodule RecruitxBackend.PanelistView do
  use RecruitxBackend.Web, :view

  def render("statistics.json", %{statistics: statistics}) do
    render_many(statistics, __MODULE__, "statistic.json")
  end

  def render("statistic.json", %{panelist: {team, signups}}) do
    %{
      team: team,
      count: signups |> Enum.count,
      signups: render_one(signups, RecruitxBackend.SignUpView, "index.json")
    }
  end

  def render("panelist.json", %{interview_panelist: interview_panelist}) do
    %{
      interview_id: interview_panelist.interview_id,
      name: interview_panelist.panelist_login_name
    }
  end

  def render("panelist.json", %{slot_panelist: slot_panelist}) do
    %{
      slot_id: slot_panelist.slot_id,
      name: slot_panelist.panelist_login_name
    }
  end
end
