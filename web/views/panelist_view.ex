defmodule RecruitxBackend.PanelistView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.TimexHelper

  def render("statistics_range.json", %{statistics_range: statistics_range}) do
    render_many(statistics_range, __MODULE__, "statistics_for_a_week.json")
  end

  def render("statistics_for_a_week.json", %{panelist: statistics_for_a_week}) do
    %{
      range: %{
        start: TimexHelper.format(statistics_for_a_week.range.starting, "%Y-%m-%d"),
        end: TimexHelper.format(statistics_for_a_week.range.ending, "%Y-%m-%d")
        },
      statistics: render_many(statistics_for_a_week.statistics, __MODULE__, "statistic.json")
    }
  end

  def render("statistics.json", %{statistics: statistics}) do
    render_many(statistics, __MODULE__, "statistic.json")
  end

  def render("statistic.json", %{panelist: {team, [[_, nil, nil, 0]]}}) do
    %{
      team: team,
      count: 0,
      signups: []
    }
  end

  def render("statistic.json", %{panelist: {team, signups}}) do
    %{
      team: team,
      count: signups |> Enum.map(&Enum.at(&1, 3)) |> Enum.reduce(0, &(&1 + &2)),
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
