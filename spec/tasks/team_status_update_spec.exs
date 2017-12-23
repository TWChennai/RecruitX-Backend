defmodule RecruitxBackend.TeamStatusUpdateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.TeamStatusUpdate

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.TeamStatusUpdate
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Timer
  alias RecruitxBackend.TimexHelper
  alias Swoosh.Templates

  describe "team status update" do
    before do: System.put_env("TW_CHENNAI_EMAIL_ADDRESS", "address")
    let :team_statuses, do: %{"Team1" => [["Team1", "Dev", "panelist1", 1]],
                              "Team2" => [["Team2", "Dev", "panelist2", 1],
                                          ["Team2", "PM", "panelist3", 2],
                                          ["Team2", "QA", "panelist4", 1],
                                          ["Team2", "Dev", "panelist5", 1]],
                              "Beach" => [["Beach", "Dev", "panelist6", 1],
                                          ["Beach", "Dev", "panelist7", 2],
                                          ["Beach", "QA", "panelist8", 1],
                                          ["Beach", "Dev", "panelist9", 1],
                                          ["Beach", "PM", "panelist10", 1],
                                        ],
                            "Team3" => [["Team1", nil, nil, 0]]
                            }
    describe "execute" do
      it "should send in correct format with stubing Templates" do
        starting = ending = TimexHelper.utc_now()
        allow Timer |> to(accept(:get_previous_week, fn -> %{starting: starting, ending: ending} end))
        allow InterviewPanelist |> to(accept(:get_statistics, fn(_) -> team_statuses() end))
        allow MailHelper |> to(accept(:deliver, fn(%{subject: "[RecruitX] Team Status Update", to: ["address"], html_body: :ok}) -> :ok end))
        allow Templates |> to(accept(:team_status_update, fn(_, _, _) -> :ok end))
        :ok = TeamStatusUpdate.execute

        expect(Timer) |> to(accepted(:get_previous_week))
        expect(InterviewPanelist) |> to(accepted(:get_statistics))
        expect(MailHelper) |> to(accepted(:deliver))
        summary_data = [%{count: 6,
                          signups: ["panelist6", "panelist7", "panelist8", "panelist9", "panelist10"],
                          team: "Beach"},
                        %{count: 1,
                          signups: ["panelist1"],
                          team: "Team1"},
                        %{count: 5,
                          signups: ["panelist2", "panelist3", "panelist4", "panelist5"],
                          team: "Team2"},
                        %{count: 0,
                          signups: [],
                          team: "Team3"},
                        ]
        expect(Templates) |> to(accepted(:team_status_update, [TimexHelper.format(starting, "%D"), TimexHelper.format(starting, "%D"), summary_data]))
      end
    end
  end
end
