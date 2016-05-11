defmodule SlotIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SlotController

  alias RecruitxBackend.Repo
  alias Timex.Date
  alias RecruitxBackend.Slot

  let :post_parameters, do: convertKeysFromAtomsToStrings(fields_for(:slot))

  describe "create" do
    it "should return 201 and be successful" do
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id)
      number_of_slots_before = (from s in Slot, select: count(s.id)) |> Repo.one
      post_parameters = Map.put(post_parameters, "start_time", get_start_of_next_week |> Date.shift(hours: 5))
      conn = action(:create, %{"slot" => Map.merge(convertKeysFromAtomsToStrings(%{count: 2}), post_parameters)})
      number_of_slots_after = (from s in Slot, select: count(s.id)) |> Repo.one

      conn |> should(be_successful)
      conn |> should(have_http_status(:created))
      expect(number_of_slots_after) |> to(be(number_of_slots_before + 2))
    end
  end
end
