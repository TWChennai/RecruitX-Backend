defmodule RecruitxBackend.ExperienceMatrixSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ExperienceMatrix

  alias RecruitxBackend.ExperienceMatrix
  alias Decimal, as: D

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
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: D.new(-1)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: {"must be in the range 0-100", [count: D.new(0)]}]))
    end

    it "when candidate_experience_upper_bound is greater than 100" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: D.new(101)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: {"must be in the range 0-100", [count: D.new(100)]}]))
    end

    it "when panelist_experience_lower_bound is lesser than 0" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: D.new(-1)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: {"must be in the range 0-100", [count: D.new(0)]}]))
    end

    it "when candidate_experience_upper_bound is greater than 100" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: D.new(101)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: {"must be in the range 0-100", [count: D.new(100)]}]))
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

  context "is_eligible" do
    it "should return true if experience is greater than maximum experience with filter" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, create(:interview_type).id)

      expect(eligiblity) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is equal to maximum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, create(:interview_type).id)

      expect(eligiblity) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is below minimum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix,panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(0.5)
      candidate_experience = D.new(0)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, create(:interview_type).id)

      expect(eligiblity) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is above minimum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, create(:interview_type).id)

      expect(eligiblity) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is within experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      create(:experience_matrix, panelist_experience_lower_bound: D.new(3))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, create(:interview_type).id)

      expect(eligiblity) |> to(be_true)
    end

    it "should return false if current interview type has filters and panelist is below minimum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      experience_matrix_create_1 = create(:experience_matrix, panelist_experience_lower_bound: D.new(2))
      experience_matrix_create_2 = create(:experience_matrix, panelist_experience_lower_bound: D.new(3))
      panelist_experience = D.new(1)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, experience_matrix_create_1.candidate_experience_upper_bound, experience_matrix_create_1.interview_type_id)

      expect(eligiblity) |> to(be_false)
    end

    it "should return true when the panelist is experienced for the current interview and candidate" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1),candidate_experience_upper_bound: D.new(2))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, experience_matrix.interview_type_id)

      expect(eligiblity) |> to(be_true)
    end

    it "should return false when the panelist is not experienced for the interview" do
      Repo.delete_all ExperienceMatrix
      experience_matrix_panelist_is_eligible_for = create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      experience_matrix_panelist_is_not_eligible_for = create(:experience_matrix, panelist_experience_lower_bound: D.new(2))
      panelist_experience = D.new(1)
      candidate_experience = experience_matrix_panelist_is_not_eligible_for.candidate_experience_upper_bound

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, experience_matrix_panelist_is_not_eligible_for.interview_type_id)

      expect(eligiblity) |> to(be_false)
    end

    it "should return false when panelist is experienced for the interview but not for the candidate" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1),candidate_experience_upper_bound: D.new(2))
      panelist_experience = D.new(1)
      candidate_experience = D.new(3)

      eligiblity = ExperienceMatrix.is_eligible(panelist_experience, candidate_experience, experience_matrix.interview_type_id)

      expect(eligiblity) |> to(be_false)
    end
  end
end
