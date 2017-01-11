defmodule RecruitxBackend.UpdateTeamSpec do
  use ESpec.Phoenix, model: RecruitxBackend.UpdateTeam

  alias RecruitxBackend.UpdateTeam
  alias RecruitxBackend.Team

  @jigsaw_url System.get_env("JIGSAW_URL")

  describe "execute" do
    let :assignment, do: %{body: "{\"project\":{\"name\":\"Recruitx\"}}", status_code: 200}
    let :panelist_details, do: create(:panelist_details)
    let :url, do: "#{@jigsaw_url}/assignments?employee_ids[]=#{panelist_details.employee_id}&current_only=true"

    before do: allow HTTPotion |> to(accept(:get, fn(_, _) -> assignment end))
    before do: allow Repo |> to(accept(:insert!, fn(_, _) -> :ok end))

    it "should fetch and update team details" do
      UpdateTeam.execute("test", panelist_details.employee_id)

      expect(HTTPotion) |> to(accepted(:get))
      expect(Repo) |> to(accepted(:insert!))
    end

    it "should not update team details if it already exists" do
      create(:team, name: "Recruitx")
      previous_count = Ectoo.count(Repo, Team)

      UpdateTeam.execute("test", panelist_details.employee_id)
      current_count = Ectoo.count(Repo, Team)

      expect(HTTPotion) |> to(accepted(:get))
      expect(previous_count) |> to(be(current_count))
    end
  end
end
