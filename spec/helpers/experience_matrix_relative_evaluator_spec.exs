defmodule RecruitxBackend.ExperienceMatrixRelativeEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ExperienceMatrix

  alias RecruitxBackend.Repo
  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.ExperienceMatrixRelativeEvaluator
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.ExperienceEligibilityData
  alias Decimal, as: D

  @lower_bound "LB"
  @upper_bound "UB"
  @empty ""

  before do: Repo.delete_all(ExperienceMatrix)

  context "evaluate" do
    it "should return true if experience is greater than maximum experience with filter (for interview)" do
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)
      role = insert(:role)
      candidate = insert(:candidate, experience: candidate_experience)
      interview = insert(:interview, candidate: candidate)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return true if experience is greater than maximum experience with filter (for slot)" do
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      role = insert(:role)
      slot = insert(:slot, role: role)
      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), slot, true)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return true if current interview type has no filters and panelist is equal to maximum experience level in experience matrix" do
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)
      role = insert(:role)
      candidate = insert(:candidate, experience: candidate_experience)
      interview = insert(:interview, candidate: candidate)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return true if current interview type has no filters and panelist is below minimum experience level in experience matrix" do
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(0.5)
      candidate_experience = D.new(0)

      candidate = insert(:candidate, experience: candidate_experience)
      interview = insert(:interview, candidate: candidate)
      role = insert(:role)
      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return true if current interview type has no filters and panelist is above minimum experience level in experience matrix" do
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = insert(:candidate, experience: candidate_experience)
      interview = insert(:interview, candidate: candidate)
      role = insert(:role)
      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return true if current interview type has no filters and panelist is within experience level in experience matrix" do
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(1))
      insert(:experience_matrix, panelist_experience_lower_bound: D.new(3))
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)

      candidate = insert(:candidate, experience: candidate_experience)
      interview = insert(:interview, candidate: candidate)
      role = insert(:role)
      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return false if current interview type has filters and panelist is below minimum experience level in experience matrix" do
      role = insert(:role)
      experience_matrix_create_1 = insert(:experience_matrix, panelist_experience_lower_bound: D.new(2), role: role)
      _experience_matrix_create_2 = insert(:experience_matrix, panelist_experience_lower_bound: D.new(3), role: role)
      panelist_experience = D.new(1)

      candidate = insert(:candidate, role: role)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix_create_1.interview_type)
      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_false())
      expect(eligiblity.satisfied_criteria) |> to(be(@empty))
    end

    it "should return true if role has no filters but current interview type has filters and panelist is below minimum experience level in experience matrix" do
      experience_matrix_create_1 = insert(:experience_matrix, panelist_experience_lower_bound: D.new(2))
      _experience_matrix_create_2 = insert(:experience_matrix, panelist_experience_lower_bound: D.new(3))
      panelist_experience = D.new(1)
      role = insert(:role)
      candidate = insert(:candidate)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix_create_1.interview_type)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return true when the panelist is experienced for the current interview and candidate" do
      role = insert(:role)
      experience_matrix = insert(:experience_matrix, panelist_experience_lower_bound: D.new(1),candidate_experience_upper_bound: D.new(2), role: role)
      panelist_experience = D.new(2)
      candidate_experience = D.new(0)
      candidate = insert(:candidate, experience: candidate_experience)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix.interview_type)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@lower_bound))
    end

    it "should return false when the panelist is not experienced for the interview" do
      role = insert(:role)
      _experience_matrix_panelist_is_eligible_for = insert(:experience_matrix, panelist_experience_lower_bound: D.new(1), role: role)
      experience_matrix_panelist_is_not_eligible_for = insert(:experience_matrix, panelist_experience_lower_bound: D.new(2), role: role)
      panelist_experience = D.new(1)
      candidate_experience = experience_matrix_panelist_is_not_eligible_for.candidate_experience_upper_bound
      candidate = insert(:candidate, experience: candidate_experience, role: role)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix_panelist_is_not_eligible_for.interview_type)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_false())
      expect(eligiblity.satisfied_criteria) |> to(be(@empty))
    end

    it "should return false when panelist is experienced for the interview but not for the candidate" do
      role = insert(:role)
      experience_matrix = insert(:experience_matrix, panelist_experience_lower_bound: D.new(1), candidate_experience_upper_bound: D.new(2), candidate_experience_lower_bound: D.new(-1), role: role)
      panelist_experience = D.new(1)
      candidate_experience = D.new(3)

      candidate = insert(:candidate, experience: candidate_experience, role: role)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix.interview_type)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(panelist_experience, role), interview, false)

      expect(eligiblity.valid?) |> to(be_false())
      expect(eligiblity.satisfied_criteria) |> to(be(@empty))
    end

    it "should return true when the panelist is eligible as the panelist 2 and not eligible for panelist 1 for any candidate" do
      role = insert(:role)
      experience_matrix = insert(:experience_matrix, panelist_experience_lower_bound: D.new(1), candidate_experience_upper_bound: D.new(5), candidate_experience_lower_bound: D.new(-1), role: role)

      candidate = insert(:candidate, experience: experience_matrix.candidate_experience_upper_bound, role: role)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix.interview_type)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(experience_matrix.panelist_experience_lower_bound, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@upper_bound))
    end

    it "should return true when the panelist is eligible as the panelist 2 not eligible for panelist 1 for this candidate" do
      role = insert(:role)
      experience_matrix = insert(:experience_matrix, panelist_experience_lower_bound: D.new(1), candidate_experience_upper_bound: D.new(99), candidate_experience_lower_bound: D.new(5), role: role)

      candidate = insert(:candidate, experience: experience_matrix.candidate_experience_upper_bound, role: role)
      interview = insert(:interview, candidate: candidate, interview_type: experience_matrix.interview_type)

      eligiblity = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(experience_matrix.panelist_experience_lower_bound, role), interview, false)

      expect(eligiblity.valid?) |> to(be_true())
      expect(eligiblity.satisfied_criteria) |> to(be(@upper_bound))
    end

    it "should return true when the panelist's role is not filtered based on panelist experience" do
      allow ExperienceMatrix |> to(accept(:should_filter_role, fn(_) -> false end))
      eligibility = ExperienceMatrixRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, populate_experience_eligibility_data(D.new(5), insert(:role)), insert(:interview), false)

      expect(eligibility.valid?) |> to(be_true())
      expect(eligibility.satisfied_criteria) |> to(be(@lower_bound))
    end
  end

  defp populate_experience_eligibility_data(panelist_experience, panelist_role) do
    %{experience_eligibility_criteria: %ExperienceEligibilityData{panelist_experience: panelist_experience,
          max_experience_with_filter: panelist_role |> ExperienceMatrix.get_max_experience_with_filter,
          interview_types_with_filter: ExperienceMatrix.get_interview_types_with_filter,
          experience_matrix_filters: (ExperienceMatrix.filter(panelist_experience, panelist_role)),
          role_ids_with_filter: ExperienceMatrix.get_role_ids_with_filter
        },
      panelist_role: panelist_role
    }
  end
end
