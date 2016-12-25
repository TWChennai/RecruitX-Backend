defmodule RecruitxBackend.WeekendDriveControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.WeekendDriveController

  let :valid_attrs, do: fields_for(:weekend_drive)
  let :weekend_drive, do: create(:weekend_drive)

  describe "create" do
    before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, weekend_drive} end))

    it "should create an event" do
      conn = action(:create, %{"weekend_drive" => valid_attrs})

      conn |> should(be_successful)
      conn |> should(have_http_status(:created))
    end
  end
end
