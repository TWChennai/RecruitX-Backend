defmodule RecruitxBackend.UpdatePanelistDetailsSpec do
  use ESpec.Phoenix, model: RecruitxBackend.UpdatePanelistDetails

  alias RecruitxBackend.UpdatePanelistDetails
  alias RecruitxBackend.PanelistDetails

  describe "execute" do
    let :panelist_details, do: insert(:panelist_details, panelist_login_name: "test")
    let :role, do: insert(:role)
    let :jigsaw_result, do: %{body: "{\"employeeId\":\"17991\",\"role\":{\"name\":\"Dev\"}}", status_code: 200}

    before do: allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result() end))

    it "should not fetch panelist details of it already exists" do
      allow Repo |> to(accept(:get, fn(PanelistDetails, "test") -> panelist_details() end))

      UpdatePanelistDetails.execute("test")

      expect(Repo) |> to(accepted(:get))
      expect(HTTPotion) |> to_not(accepted(:get))
    end

    it "should fetch and update panelist details when it is not present" do
      allow Repo |> to(accept(:get, fn(PanelistDetails, "test") -> nil end))
      allow Repo |> to(accept(:insert!, fn(PanelistDetails, _) -> :ok end))

      UpdatePanelistDetails.execute("test")

      expect(HTTPotion) |> to(accepted(:get))
      expect(Repo) |> to(accepted(:insert!))
    end
  end
end
