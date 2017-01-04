defmodule SlotIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SlotController

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Slot
  alias RecruitxBackend.TimexHelper

  describe "create" do
    xit "should return 201 and be successful" do
      candidate = insert(:candidate)
      insert(:interview, start_time: get_start_of_next_week(), interview_type: insert(:interview_type, priority: 1), candidate: candidate)
      number_of_slots_before = (from s in Slot, select: count(s.id)) |> Repo.one
      post_parameters = convertKeysFromAtomsToStrings(params_for(:slot, role_id: candidate.role_id, start_time: get_start_of_next_week() |> TimexHelper.add(5, :hours), count: 2))
      conn = action(:create, %{"slot" => post_parameters})
      number_of_slots_after = (from s in Slot, select: count(s.id)) |> Repo.one

      conn |> should(be_successful())
      conn |> should(have_http_status(:created))
      expect(number_of_slots_after) |> to(be(number_of_slots_before + 2))
    end
  end

  describe "delete" do
    it "should return 200 with successfully slot is deleted" do
      Repo.delete_all Slot
      created_slot = insert(:slot)
      expect((from s in Slot, select: count(s.id)) |> Repo.all) |> to(be([1]))
      conn = action(:delete, %{"id" => created_slot.id})

      conn |> should(be_successful())
      expect((from s in Slot, select: count(s.id)) |> Repo.all) |> to(be([0]))
    end
  end

  describe "index" do
    before do: Repo.delete_all Slot
    let :created_slot, do: insert(:slot)

    it "should return 200 with no slots when there are no slots" do
      conn = action(:index, %{"interview_type_id" => 1, "previous_rounds_start_time" => format_datetime(TimexHelper.utc_now()), "role_id" => 1})

      conn |> should(be_successful())
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with no slots when there are past slots" do
      conn = action(:index, %{"interview_type_id" => created_slot().interview_type_id, "previous_rounds_start_time" => format_datetime(created_slot().start_time |> TimexHelper.add(2, :hours)), "role_id" => created_slot().role_id})

      conn |> should(be_successful())
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with no slots when there are no slots for matching role" do
      conn = action(:index, %{"interview_type_id" => created_slot().interview_type_id, "previous_rounds_start_time" => format_datetime(created_slot().start_time |> TimexHelper.add(2, :hours)), "role_id" => (created_slot().role_id + 1)})

      conn |> should(be_successful())
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with no slots when there are no slots for matching interview type" do
      conn = action(:index, %{"interview_type_id" => created_slot().interview_type_id + 1, "previous_rounds_start_time" => format_datetime(created_slot().start_time |> TimexHelper.add(2, :hours)), "role_id" => created_slot().role_id})

      conn |> should(be_successful())
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with slots when there are slots" do
      conn = action(:index, %{"interview_type_id" => created_slot().interview_type_id, "previous_rounds_start_time" => format_datetime(created_slot().start_time |> TimexHelper.add(-2, :hours)), "role_id" => created_slot().role_id})
      conn |> should(be_successful())
      expect(Enum.at(conn.assigns.slots, 0).id) |> to(be(created_slot().id))
    end
  end

  defp format_datetime(datetime), do: TimexHelper.format(datetime, "%Y-%m-%dT%H:%M:%SZ")
end
