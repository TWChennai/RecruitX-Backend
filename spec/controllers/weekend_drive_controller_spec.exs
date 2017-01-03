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

  describe "index" do
    let :weekend_drives do
      create_list(3,:weekend_drive)
    end
    before do: allow Repo |> to(accept(:all, fn(_) -> weekend_drives end))
    subject do: action :index
    it do: should be_successful
    it do: should have_http_status(:ok)
    it "should return the array of weekend drive as a JSON response" do
      response = action(:index)
      expect(response.assigns.weekend_drives) |> to(eq(weekend_drives))
    end
  end

  describe "show" do
    let :weekend_drive do
      create(:weekend_drive, id: 1)
    end
    before do: allow Repo |> to(accept(:get, fn(_,1) -> weekend_drive end))

    subject do: action(:show, %{"id" => weekend_drive.id})
    it do: should be_successful
    it do: should have_http_status(:ok)

    context "not found" do
      before do: allow Repo |> to(accept(:get, fn(_, 1) -> nil end))
      it "raises exception" do
        response = action(:show, %{"id" => 1})
        response |> should_not(be_successful)
        response |> should(have_http_status(:not_found))
      end
    end
  end

  describe "update" do
    let :weekend_drive, do: create(:weekend_drive)

    describe "valid params" do
      before do: allow Repo |> to(accept(:update, fn(_) -> { :ok, weekend_drive } end))
      subject do: action(:update,%{"id"=> weekend_drive.id, "weekend_drive"=>%{"role_id"=>4}})
      it do: should be_successful
      it do: should have_http_status(:ok)
    end
    describe "invalid params" do
      before do: allow Repo |> to(accept(:update, fn(c) -> { :error, c} end))
      subject do: action(:update,%{"id"=> weekend_drive.id, "weekend_drive"=>%{"role_id"=>1000}})
      it do: should_not(be_successful)
      it do: should(have_http_status(:unprocessable_entity))
    end
  end

end
