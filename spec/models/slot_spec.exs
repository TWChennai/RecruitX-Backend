defmodule RecruitxBackend.SlotSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Slot

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.TimexHelper

  let :experience, do: Decimal.new(1.0)
  let :candidate, do: create(:candidate, experience: experience)
  let :valid_attrs, do: %{
                  "start_time" => get_start_of_next_week |> TimexHelper.add(5, :hours) |> TimexHelper.format("%Y-%m-%d %H:%M:%S"),
                  "role_id" => candidate.role_id,
                  "interview_type_id" => create(:interview_type, priority: 2).id,
                  "count" => 1
                }
  let :invalid_attrs, do: %{}

  context "valid changeset" do

    subject do: Slot.changeset(%Slot{}, valid_attrs)

    it "should be valid if there are valid interview" do
      create(:interview, start_time: get_start_of_next_week, interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
      changeset = Slot.changeset(%Slot{}, valid_attrs)
      expect(changeset) |> to(be_valid)
    end

    it "should be invalid when there are no valid interview" do
      Repo.delete_all(Interview)
      changeset = Slot.changeset(%Slot{}, valid_attrs)

      expect(changeset) |> to(have_errors([slots: "No Interviews has been scheduled!"]))
    end

    it "pre populate avg experience and skills of a candidate scheduled on the day" do
      Repo.delete_all(Interview)
      create(:interview, start_time: get_start_of_next_week, interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)

      changeset = Slot.changeset(%Slot{}, valid_attrs)
      expect(changeset.changes.skills) |> to(be("Skill 1/Skill 2"))
      expect(changeset.changes.average_experience) |> to(be(experience))
    end

    it "pre populate avg experience and skills of all candidates scheduled on the day" do
      Repo.delete_all(Interview)
      candidate2 = create(:candidate, experience: experience, role_id: candidate.role_id)
      create(:interview, start_time: get_start_of_next_week, interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
      create(:interview, start_time: get_start_of_next_week, interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate2.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)

      changeset = Slot.changeset(%Slot{}, valid_attrs)
      expect(changeset.changes.skills) |> to(be("Skill 1/Skill 2"))
      expect(changeset.changes.average_experience) |> to(be(experience))
    end
  end

  context "delete_unused_slots" do
    it "should not delete anything if there are no past slots" do
      Repo.delete_all(Slot)
      create(:slot, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :days))
      slot_count_before = (from s in Slot, select: count(s.id)) |> Repo.one

      Slot.delete_unused_slots
      slot_count_after = (from s in Slot, select: count(s.id)) |> Repo.one

      expect(slot_count_after) |> to(be(slot_count_before))
    end

    it "should delete only slots if there are past slots and no signups" do
      Repo.delete_all(Slot)
      create(:slot, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      slot_count_before = (from s in Slot, select: count(s.id)) |> Repo.one

      Slot.delete_unused_slots
      slot_count_after = (from s in Slot, select: count(s.id)) |> Repo.one

      expect(slot_count_after) |> to(be(slot_count_before - 1))
    end

    it "should delete slots and slot_panelists if there are past slots and signups" do
      Repo.delete_all(Slot)
      Repo.delete_all(SlotPanelist)
      slot = create(:slot, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      create(:slot_panelist, slot_id: slot.id)
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
