defmodule RecruitxBackend.TeamStatusUpdate do

  alias RecruitxBackend.Timer
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.InterviewPanelist
  alias Swoosh.Templates
  alias RecruitxBackend.MailHelper

  def execute do
    %{starting: starting, ending: ending} = previous_week = Timer.get_previous_week
    status = previous_week
              |> InterviewPanelist.get_statistics
    summary = status |> construct_summary_data

    recepient = System.get_env("TW_CHENNAI_EMAIL_ADDRESS")
    start_date = TimexHelper.format(starting, "%D")
    to_date = TimexHelper.format(ending, "%D")
    email_content = Templates.team_status_update(start_date, to_date, summary)

    MailHelper.deliver(%{
      subject: "[RecruitX] Team Status Update",
      to: recepient |> String.split,
      html_body: email_content
    })
  end

  defp construct_summary_data(status) do
    status
    |> Enum.map(fn a ->
        case a do
          {team, [[_, nil, nil, 0]]} -> %{team: team, count: 0, signups: []}
          {team, signups} -> %{team: team, count: signups |> Enum.map(&Enum.at(&1, 3)) |> Enum.reduce(0, &(&1 + &2)), signups: signups |> Enum.map(fn x -> Enum.at(x, 2) end)}
        end
    end)
    |> Enum.sort(&(&1.team < &2.team))
  end
end
