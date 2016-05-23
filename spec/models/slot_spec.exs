defmodule RecruitxBackend.SlotSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Slot

  alias RecruitxBackend.Slot
  alias RecruitxBackend.Interview

  let :experience, do: Decimal.new(1.0)
  let :candidate, do: create(:candidate, experience: experience)
  let :valid_attrs, do: %{
                  "start_time" => get_start_of_next_week |> Timex.Date.shift(hours: 5) |> Timex.DateFormat.format!("%Y-%m-%d %H:%M:%S", :strftime),
                  "role_id" => candidate.role_id,
                  "interview_type_id" => create(:interview_type, priority: 2).id,
                  "count" => 1
                }
  let :invalid_attrs, do: %{}

  context "valid changeset" do

    subject do: Slot.changeset(%Slot{}, valid_attrs)

    it "should be valid if there are valid interview" do
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
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
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)

      changeset = Slot.changeset(%Slot{}, valid_attrs)
      expect(changeset.changes.skills) |> to(be("Skill 1/Skill 2"))
      expect(changeset.changes.average_experience) |> to(be(experience))
    end

    it "pre populate avg experience and skills of all candidates scheduled on the day" do
      Repo.delete_all(Interview)
      candidate2 = create(:candidate, experience: experience, role_id: candidate.role_id)
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate.id)
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id, candidate_id: candidate2.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)

      changeset = Slot.changeset(%Slot{}, valid_attrs)
      expect(changeset.changes.skills) |> to(be("Skill 1/Skill 2"))
      expect(changeset.changes.average_experience) |> to(be(experience))
    end
  end
end
