defmodule RecruitxBackend.CandidateSkillSpec do
  use ESpec.Phoenix, model: RecruitxBackend.CandidateSkill

  import RecruitxBackend.Factory

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Skill

  let :candidate, do: create(:candidate, additional_information: "info")
  let :skill, do: create(:skill)

  let :valid_attrs, do: fields_for(:candidate_skill, candidate_id: candidate.id, skill_id: skill.id)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: CandidateSkill.changeset(%CandidateSkill{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: CandidateSkill.changeset(%CandidateSkill{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([candidate_id: "can't be blank", skill_id: "can't be blank"])

    it "when candidate id is nil" do
      candidate_skill_with_candidate_id_nil = Map.merge(valid_attrs, %{candidate_id: nil})

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when skill id is nil" do
      candidate_skill_with_skill_id_nil = Map.merge(valid_attrs, %{skill_id: nil})

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_skill_id_nil)

      expect(result) |> to(have_errors(skill_id: "can't be blank"))
    end

    it "when candidate id is not present" do
      candidate_skill_with_no_candidate_id = Map.delete(valid_attrs, :candidate_id)

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_no_candidate_id)

      expect(result) |> to(have_errors(candidate_id: "can't be blank"))
    end

    it "when skill id is not present" do
      candidate_skill_with_no_skill_id = Map.delete(valid_attrs, :skill_id)

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_no_skill_id)

      expect(result) |> to(have_errors(skill_id: "can't be blank"))
    end
  end

  context "foreign key constraint" do
    it "when candidate id not present in candidates table" do
      # TODO: Not sure why Ectoo.max(Repo, Candidate, :id) is failing - need to investigate
      current_candidate_count = Ectoo.count(Repo, Candidate)
      candidate_id_not_present = current_candidate_count + 1
      candidate_skill_with_invalid_candidate_id = Map.merge(valid_attrs, %{candidate_id: candidate_id_not_present})

      changeset = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_invalid_candidate_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate_id: "does not exist"]))
    end

    it "when skill id not present in skills table" do
      # TODO: Not sure why Ectoo.max(Repo, Skill, :id) is failing - need to investigate
      current_skill_count = Ectoo.count(Repo, Skill)
      skill_id_not_present = current_skill_count + 1
      candidate_skill_with_invalid_skill_id = Map.merge(valid_attrs, %{skill_id: skill_id_not_present})

      changeset = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_invalid_skill_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([skill_id: "does not exist"]))
    end
  end
end
