defmodule SlotIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SlotController

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Slot

  let :post_parameters, do: convertKeysFromAtomsToStrings(fields_for(:slot))

  describe "create" do
    it "should return 201 and be successful" do
      number_of_slots_before = (from s in Slot, select: count(s.id)) |> Repo.one
      conn = action(:create, %{"slot" => Map.merge(convertKeysFromAtomsToStrings(%{count: 2}), post_parameters)})
      number_of_slots_after = (from s in Slot, select: count(s.id)) |> Repo.one

      conn |> should(be_successful)
      conn |> should(have_http_status(:created))
      expect(number_of_slots_after) |> to(be(number_of_slots_before + 2))
    end
  end
end
