defmodule RecruitxBackend.SlotSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Slot

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.TimexHelper

  let :experience, do: Decimal.new(1.0)
  let :candidate, do: insert(:candidate, experience: experience())
  # TODO: Use ex-machina factory here
  let :valid_attrs, do: %{
                  "start_time" => get_start_of_next_week() |> TimexHelper.add(5, :hours),
                  "role_id" => candidate().role_id,
                  "interview_type_id" => insert(:interview_type, priority: 2).id,
                  "count" => 1
                }
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    before do: Repo.delete_all(Interview)

    subject do: Slot.changeset(%Slot{}, valid_attrs())

    it "should be valid if there are valid interview" do
      insert(:interview, start_time: get_start_of_next_week(), interview_type: insert(:interview_type, priority: 1), candidate: candidate())
      changeset = Slot.changeset(%Slot{}, valid_attrs())
      expect(changeset) |> to(be_valid())
    end

    it "should be invalid when there are no valid interview" do
      changeset = Slot.changeset(%Slot{}, valid_attrs())

      expect(changeset) |> to(have_errors([slots: {"No Interviews has been scheduled!", []}]))
    end

    it "pre populate avg experience and skills of a candidate scheduled on the day" do
      insert(:interview, start_time: get_start_of_next_week(), interview_type: insert(:interview_type, priority: 1), candidate: candidate())
      insert(:candidate_skill, skill: insert(:skill, name: "Skill 1"), candidate: candidate())
      insert(:candidate_skill, skill: insert(:skill, name: "Skill 2"), candidate: candidate())

      changeset = Slot.changeset(%Slot{}, valid_attrs())
      expect(changeset.changes.skills) |> to(be("Skill 1/Skill 2"))
      expect(changeset.changes.average_experience) |> to(be(experience()))
    end

    it "pre populate avg experience and skills of all candidates scheduled on the day" do
      candidate2 = insert(:candidate, experience: experience(), role: candidate().role)
      insert(:interview, start_time: get_start_of_next_week(), interview_type: insert(:interview_type, priority: 1), candidate: candidate())
      insert(:interview, start_time: get_start_of_next_week(), interview_type: insert(:interview_type, priority: 1), candidate: candidate2)
      insert(:candidate_skill, skill: insert(:skill, name: "Skill 1"), candidate: candidate())
      insert(:candidate_skill, skill: insert(:skill, name: "Skill 2"), candidate: candidate())

      changeset = Slot.changeset(%Slot{}, valid_attrs())
      expect(changeset.changes.skills) |> to(be("Skill 1/Skill 2"))
      expect(changeset.changes.average_experience) |> to(be(experience()))
    end
  end

  context "delete_unused_slots" do
    before do: Repo.delete_all(Slot)

    it "should not delete anything if there are no past slots" do
      insert(:slot, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :days))
      slot_count_before = (from s in Slot, select: count(s.id)) |> Repo.one

      Slot.delete_unused_slots
      slot_count_after = (from s in Slot, select: count(s.id)) |> Repo.one

      expect(slot_count_after) |> to(be(slot_count_before))
    end

    it "should delete only slots if there are past slots and no signups" do
      insert(:slot, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      slot_count_before = (from s in Slot, select: count(s.id)) |> Repo.one

      Slot.delete_unused_slots
      slot_count_after = (from s in Slot, select: count(s.id)) |> Repo.one

      expect(slot_count_after) |> to(be(slot_count_before - 1))
    end

    it "should delete slots and slot_panelists if there are past slots and signups" do
      Repo.delete_all(SlotPanelist)
      slot = insert(:slot, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      insert(:slot_panelist, slot: slot)
      slot_count_before = (from s in Slot, select: count(s.id)) |> Repo.one
      slot_panelist_count_before = (from sp in SlotPanelist, select: count(sp.id)) |> Repo.one

      Slot.delete_unused_slots
      slot_count_after = (from s in Slot, select: count(s.id)) |> Repo.one
      slot_panelist_count_after = (from sp in SlotPanelist, select: count(sp.id)) |> Repo.one

      expect(slot_count_after) |> to(be(slot_count_before - 1))
      expect(slot_panelist_count_after) |> to(be(slot_panelist_count_before - 1))
    end
  end
end
