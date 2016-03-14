defmodule RecruitxBackend.ExperienceMatrixSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ExperienceMatrix

  alias RecruitxBackend.ExperienceMatrix

  let :valid_attrs, do: fields_for(:experience_matrix)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: ExperienceMatrix.changeset(%ExperienceMatrix{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: ExperienceMatrix.changeset(%ExperienceMatrix{}, invalid_attrs)

    it do: should_not be_valid

    it do: should have_errors([panelist_experience_lower_bound: "can't be blank", candidate_experience_upper_bound: "can't be blank", interview_type_id: "can't be blank"])

    it "when panelist_experience_lower_bound is nil" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: nil}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: "can't be blank"]))
    end

    it "when candidate_experience_upper_bound is nil" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: nil}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: "can't be blank"]))
    end

    it "when interview_type_id is nil" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{interview_type_id: nil}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([interview_type_id: "can't be blank"]))
    end

    it "when candidate_experience_upper_bound is lesser than 0" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: -1}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: {"must be in the range 0-100", [count: 0]}]))
    end

    it "when candidate_experience_upper_bound is greater than 100" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: 101}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: {"must be in the range 0-100", [count: 100]}]))
    end

    it "when panelist_experience_lower_bound is lesser than 0" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: -1}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: {"must be in the range 0-100", [count: 0]}]))
    end

    it "when candidate_experience_upper_bound is greater than 100" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: 101}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: {"must be in the range 0-100", [count: 100]}]))
    end
  end

  context "association constraint" do
    it "when interview_type_id does not exist" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{interview_type_id: 0}))
      {result, changeset} = Repo.insert(changeset)

      expect(result) |> to(be(:error))
      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([interview_type: "does not exist"]))
    end
  end

  context "unique constraint" do
    it "when panelist_experience_lower_bound,interview_type_id,candidate_experience_upper_bound already exist" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, valid_attrs)
      Repo.insert(changeset)
      {result, changeset} = Repo.insert(changeset)

      expect(result) |> to(be(:error))
      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([experience_matrix_unique: "This criteria is already specified"]))
    end
  end
end
