defmodule SlotIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SlotController

  alias RecruitxBackend.Repo
  alias Timex.Date
  alias Timex.DateFormat
  alias RecruitxBackend.Slot

  let :candidate, do: create(:candidate)
  let :post_parameters, do: convertKeysFromAtomsToStrings(fields_for(:slot, role_id: candidate.role_id))

  describe "create" do
    it "should return 201 and be successful" do
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
      number_of_slots_before = (from s in Slot, select: count(s.id)) |> Repo.one
      post_parameters = Map.put(post_parameters, "start_time", get_start_of_next_week |> Date.shift(hours: 5))
      conn = action(:create, %{"slot" => Map.merge(convertKeysFromAtomsToStrings(%{count: 2}), post_parameters)})
      number_of_slots_after = (from s in Slot, select: count(s.id)) |> Repo.one

      conn |> should(be_successful)
      conn |> should(have_http_status(:created))
      expect(number_of_slots_after) |> to(be(number_of_slots_before + 2))
    end
  end

  describe "index" do
    let :created_slot, do: create(:slot)

    it "should return 200 with no slots when there are no slots" do
      conn = action(:index, %{"interview_type_id" => 1, "previous_rounds_start_time" => DateFormat.format!(Date.now, "%Y-%m-%dT%H:%M:%SZ", :strftime), "role_id" => 1})

      conn |> should(be_successful)
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with no slots when there are past slots" do
      conn = action(:index, %{"interview_type_id" => created_slot.interview_type_id, "previous_rounds_start_time" => DateFormat.format!((created_slot.start_time |> Date.shift(hours: 2)), "%Y-%m-%dT%H:%M:%SZ", :strftime), "role_id" => created_slot.role_id})

      conn |> should(be_successful)
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with no slots when there are no slots for matching role" do
      conn = action(:index, %{"interview_type_id" => created_slot.interview_type_id, "previous_rounds_start_time" => DateFormat.format!((created_slot.start_time |> Date.shift(hours: 2)), "%Y-%m-%dT%H:%M:%SZ", :strftime), "role_id" => (created_slot.role_id + 1)})

      conn |> should(be_successful)
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with no slots when there are no slots for matching interview type" do
      conn = action(:index, %{"interview_type_id" => created_slot.interview_type_id + 1, "previous_rounds_start_time" => DateFormat.format!((created_slot.start_time |> Date.shift(hours: 2)), "%Y-%m-%dT%H:%M:%SZ", :strftime), "role_id" => created_slot.role_id})

      conn |> should(be_successful)
      expect(conn.assigns.slots) |> to(be([]))
    end

    it "should return 200 with slots when there are slots" do
      conn = action(:index, %{"interview_type_id" => created_slot.interview_type_id, "previous_rounds_start_time" => DateFormat.format!((created_slot.start_time |> Date.shift(hours: -2)), "%Y-%m-%dT%H:%M:%SZ", :strftime), "role_id" => created_slot.role_id})

      conn |> should(be_successful)
      expect(conn.assigns.slots) |> to(be([created_slot]))
    end
  end

end
