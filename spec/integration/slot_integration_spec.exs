defmodule SlotIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SlotController

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Interview
  alias RecruitxBackend.TimexHelper

  describe "create" do
    it "should return 201 and be successful" do
      number_of_slots_to_be_inserted = 2
      number_of_slots_before = Slot.count
      candidate = insert(:candidate)
      insert(:interview, start_time: get_start_of_next_week(), interview_type: insert(:interview_type, priority: 1), candidate: candidate)
      slot_params = params_for(:slot, role_id: candidate.role_id, start_time: get_start_of_next_week() |> TimexHelper.add(5, :hours), interview_type_id: insert(:interview_type, priority: 2).id)
      post_parameters = convertKeysFromAtomsToStrings(Map.merge(slot_params, %{count: number_of_slots_to_be_inserted}))
      conn = action(:create, %{"slot" => post_parameters})

      conn |> should(be_successful())
      conn |> should(have_http_status(:created))
      expect(Slot.count) |> to(be(number_of_slots_before + number_of_slots_to_be_inserted))
    end

    it "should convert the slot to interview" do
      candidate = insert(:candidate)
      number_of_slots_before = Slot.count
      number_of_interviews_before = Interview.count
      slot = insert(:slot)
      conn = action(:create, %{"slot_id" => slot.id, "candidate_id" => candidate.id})

      conn |> should(be_successful())
      conn |> should(have_http_status(:created))
      expect(Slot.count) |> to(be(number_of_slots_before))
      expect(Interview.count) |> to(be(number_of_interviews_before + 1))
    end

    it "should convert the slot to interview and add those signup panelists to that interview" do
      candidate = insert(:candidate)
      slot_panelist = insert(:slot_panelist)
      number_of_slot_panelists_before = SlotPanelist.count
      number_of_interview_panelists_before = InterviewPanelist.count
      conn = action(:create, %{"slot_id" => slot_panelist.slot.id, "candidate_id" => candidate.id})

      conn |> should(be_successful())
      conn |> should(have_http_status(:created))
      expect(SlotPanelist.count) |> to(be(number_of_slot_panelists_before - 1))
      expect(InterviewPanelist.count) |> to(be(number_of_interview_panelists_before + 1))
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
