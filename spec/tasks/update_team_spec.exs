defmodule RecruitxBackend.UpdateTeamSpec do
  use ESpec.Phoenix, model: RecruitxBackend.UpdateTeam

  alias RecruitxBackend.UpdateTeam
  alias RecruitxBackend.Team
  alias RecruitxBackend.UserController

  @jigsaw_url System.get_env("JIGSAW_URL")

  describe "execute" do
    let :assignment, do: %{body: "[{\"project\":{\"name\":\"Recruitx\"}}]", status_code: 200}
    let :employee_id, do: 12345

    describe "panelist assigned to some project" do
      before do: allow UserController |> to(accept(:get_data_safely, fn("#{@jigsaw_url}/assignments?employee_ids[]=12345&current_only=true") -> assignment() end))

      it "should fetch and update team details" do
        allow Repo |> to(accept(:insert!, fn(%{changes: %{name: "Recruitx"}}) -> :ok end))
        UpdateTeam.execute(employee_id())

        expect(UserController) |> to(accepted(:get_data_safely))
        expect(Repo) |> to(accepted(:insert!))
      end

      it "should not update team details if it already exists" do
        insert(:team, name: "Recruitx")
        allow Repo |> to(accept(:insert!, fn(%{changes: %{name: "Recruitx"}}) -> :ok end))
        previous_count = Team.count

        UpdateTeam.execute(employee_id())
        current_count = Team.count

        expect(UserController) |> to(accepted(:get_data_safely))
        expect(previous_count) |> to(be(current_count))
      end
    end

    describe "panelist not assigned to any project" do
      before do: allow UserController |> to(accept(:get_data_safely, fn("#{@jigsaw_url}/assignments?employee_ids[]=12345&current_only=true") -> %{body: "[]", status_code: 200} end))
      before do: allow Repo |> to(accept(:insert!, fn(%{changes: %{name: "Beach"}}) -> :ok end))

      it "should fetch and update team details" do
        UpdateTeam.execute(employee_id())

        expect(UserController) |> to(accepted(:get_data_safely))
        expect(Repo) |> to(accepted(:insert!))
      end
    end
  end
end
