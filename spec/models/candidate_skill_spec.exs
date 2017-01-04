defmodule RecruitxBackend.CandidateSkillSpec do
  use ESpec.Phoenix, model: RecruitxBackend.CandidateSkill

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Skill

  let :valid_attrs, do: params_with_assocs(:candidate_skill)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: CandidateSkill.changeset(%CandidateSkill{}, valid_attrs())

    it do: should be_valid()
  end

  context "invalid changeset" do
    subject do: CandidateSkill.changeset(%CandidateSkill{}, invalid_attrs())

    it do: should_not be_valid()
    it do: should have_errors([candidate_id: {"can't be blank", [validation: :required]}, skill_id: {"can't be blank", [validation: :required]}])

    it "when candidate id is nil" do
      candidate_skill_with_candidate_id_nil = Map.merge(valid_attrs(), %{candidate_id: nil})

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_candidate_id_nil)

      expect(result) |> to(have_errors(candidate_id: {"can't be blank", [validation: :required]}))
    end

    it "when skill id is nil" do
      candidate_skill_with_skill_id_nil = Map.merge(valid_attrs(), %{skill_id: nil})

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_skill_id_nil)

      expect(result) |> to(have_errors(skill_id: {"can't be blank", [validation: :required]}))
    end

    it "when candidate id is not present" do
      candidate_skill_with_no_candidate_id = Map.delete(valid_attrs(), :candidate_id)

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_no_candidate_id)

      expect(result) |> to(have_errors(candidate_id: {"can't be blank", [validation: :required]}))
    end

    it "when skill id is not present" do
      candidate_skill_with_no_skill_id = Map.delete(valid_attrs(), :skill_id)

      result = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_no_skill_id)

      expect(result) |> to(have_errors(skill_id: {"can't be blank", [validation: :required]}))
    end
  end

  context "foreign key constraint" do
    it "when candidate id not present in candidates table" do
      current_candidate_count = Candidate.max(:id)
      candidate_id_not_present = current_candidate_count + 100
      candidate_skill_with_invalid_candidate_id = Map.merge(valid_attrs(), %{candidate_id: candidate_id_not_present})

      changeset = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_invalid_candidate_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([candidate: {"does not exist", []}]))
    end

    it "when skill id not present in skills table" do
      current_skill_count = Skill.max(:id)
      skill_id_not_present = current_skill_count + 100
      candidate_skill_with_invalid_skill_id = Map.merge(valid_attrs(), %{skill_id: skill_id_not_present})

      changeset = CandidateSkill.changeset(%CandidateSkill{}, candidate_skill_with_invalid_skill_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([skill: {"does not exist", []}]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same skil is added more than once for a candidate" do
      changeset = CandidateSkill.changeset(%CandidateSkill{}, valid_attrs())
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([skill_id: {"has already been taken", []}]))
    end
  end
end
