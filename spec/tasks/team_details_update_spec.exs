defmodule RecruitxBackend.TeamDetailsUpdateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.TeamDetailsUpdate

  alias RecruitxBackend.TeamDetailsUpdate
  alias RecruitxBackend.UpdatePanelistDetails
  alias RecruitxBackend.UpdateTeam

  describe "update team details" do

    describe "execute" do

      it "should call update the same number of times as unprocessed update team details" do
        allow UpdatePanelistDetails |> to(accept(:execute, fn(_) -> %{employee_id: 123} end))
        allow UpdateTeam |> to(accept(:execute, fn(_, _) -> %{employee_id: 123} end))
        insert(:update_team_details)
        insert(:update_team_details)
        insert(:update_team_details)
        insert(:update_team_details, processed: true)

        TeamDetailsUpdate.execute

        expect(UpdatePanelistDetails) |> to(accepted(:execute, :any, count: 3))
        expect(UpdateTeam) |> to(accepted(:execute, :any, count: 3))
      end
    end
  end
end
