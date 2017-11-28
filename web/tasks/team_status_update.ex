defmodule RecruitxBackend.TeamStatusUpdate do

  alias RecruitxBackend.Timer
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo
  alias Swoosh.Templates
  alias RecruitxBackend.MailHelper

  def execute do
    %{starting: starting, ending: ending} = current_week = Timer.get_current_week
    status = current_week
              |> InterviewPanelist.get_statistics
              |> Repo.all
              |> Enum.group_by(&Enum.at(&1, 0))

    summary = status |> Enum.map(fn a ->
        case a do
          {team, [[_, nil, nil, 0]]} -> %{team: team, count: 0, signups: []}
          {team, signups} -> %{team: team, count: signups |> Enum.map(&Enum.at(&1, 3)) |> Enum.reduce(0, &(&1+&2)), signups: format_signups(signups)}
        end
    end) |> Enum.sort(&(&1.count >= &2.count))

    recepient = System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES")
    start_date = TimexHelper.format(starting, "%D")
    to_date = TimexHelper.format(ending, "%D")
    email_content = Templates.team_status_update(start_date, to_date, summary)

    MailHelper.deliver(%{
      subject: "[RecruitX] Team Status Update",
      to: recepient |> String.split,
      html_body: email_content
    })
  end

  defp format_signups(signups), do: signups |> Enum.group_by(&Enum.at(&1, 1)) |> Enum.map(fn {a,b} -> {a, Enum.map(b, &tl(&1)) |> Enum.map(&tl(&1))} end)
end
