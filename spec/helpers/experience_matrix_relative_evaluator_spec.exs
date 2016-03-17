defmodule RecruitxBackend.ExperienceMatrixRelativeEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ExperienceMatrix

  alias RecruitxBackend.Repo
  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.ExperienceMatrixRelativeEvaluator
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.ExperienceEligibilityData
  alias Decimal, as: D

  context "evaluate" do
    it "should return true if experience is greater than maximum experience with filter" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id, candidate_id: candidate.id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is equal to maximum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is below minimum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix,panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(0.5)
      candidate_experience = D.new(0)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is above minimum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_true)
    end

    it "should return true if current interview type has no filters and panelist is within experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      create(:experience_matrix, panelist_experience_lower_bound: D.new(3))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_true)
    end

    it "should return false if current interview type has filters and panelist is below minimum experience level in experience matrix" do
      Repo.delete_all ExperienceMatrix
      experience_matrix_create_1 = create(:experience_matrix, panelist_experience_lower_bound: D.new(2))
      _experience_matrix_create_2 = create(:experience_matrix, panelist_experience_lower_bound: D.new(3))
      panelist_experience = D.new(1)

      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id, interview_type_id: experience_matrix_create_1.interview_type_id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_false)
    end

    it "should return true when the panelist is experienced for the current interview and candidate" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1),candidate_experience_upper_bound: D.new(2))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id, interview_type_id: experience_matrix.interview_type_id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_true)
    end

    it "should return false when the panelist is not experienced for the interview" do
      Repo.delete_all ExperienceMatrix
      _experience_matrix_panelist_is_eligible_for = create(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      experience_matrix_panelist_is_not_eligible_for = create(:experience_matrix, panelist_experience_lower_bound: D.new(2))
      panelist_experience = D.new(1)
      candidate_experience = experience_matrix_panelist_is_not_eligible_for.candidate_experience_upper_bound

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id, interview_type_id: experience_matrix_panelist_is_not_eligible_for.interview_type_id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_false)
    end

    it "should return false when panelist is experienced for the interview but not for the candidate" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix, panelist_experience_lower_bound: D.new(1),candidate_experience_upper_bound: D.new(2))
      panelist_experience = D.new(1)
      candidate_experience = D.new(3)

      candidate = create(:candidate, experience: candidate_experience)
      interview = create(:interview, candidate_id: candidate.id, interview_type_id: experience_matrix.interview_type_id)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience), interview)

      expect(eligiblity.valid?) |> to(be_false)
    end
  end

  defp populate_experience_eligibility_data(panelist_experience) do
    %ExperienceEligibilityData{panelist_experience: panelist_experience,
      max_experience_with_filter: ExperienceMatrix.get_max_experience_with_filter,
      interview_types_with_filter: ExperienceMatrix.get_interview_types_with_filter,
      experience_matrix_filters: (ExperienceMatrix.filter(panelist_experience)) |> Repo.all
    }
  end
end
