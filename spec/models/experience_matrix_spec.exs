defmodule RecruitxBackend.ExperienceMatrixSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ExperienceMatrix

  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.Role
  alias Decimal

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

    it "when role_id is nil" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{role_id: nil}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([role_id: "can't be blank"]))
    end

    it "when candidate_experience_upper_bound is lesser than 0" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: Decimal.new(-1)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: {"must be in the range 0-100", [count: Decimal.new(0)]}]))
    end

    it "when candidate_experience_upper_bound is greater than 100" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{candidate_experience_upper_bound: Decimal.new(101)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([candidate_experience_upper_bound: {"must be in the range 0-100", [count: Decimal.new(100)]}]))
    end

    it "when panelist_experience_lower_bound is lesser than 0" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: Decimal.new(-1)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: {"must be in the range 0-100", [count: Decimal.new(0)]}]))
    end

    it "when candidate_experience_upper_bound is greater than 100" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{panelist_experience_lower_bound: Decimal.new(101)}))

      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([panelist_experience_lower_bound: {"must be in the range 0-100", [count: Decimal.new(100)]}]))
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

    it "should throw error when role does not exist" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{role_id: 0}))
      {result, changeset} = Repo.insert(changeset)

      expect result |> to(be(:error))
      expect changeset.valid? |> to(be_false)
      expect changeset.errors |> to(eql([role: "does not exist"]))
    end
  end

  context "unique constraint" do
    it "when panelist_experience_lower_bound, interview_type_id, candidate_experience_upper_bound, candidate_experience_lower_bound, role already exist" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, valid_attrs)
      Repo.insert(changeset)
      {result, changeset} = Repo.insert(changeset)

      expect(result) |> to(be(:error))
      expect(changeset.valid?) |> to(be_false)
      expect(changeset.errors) |> to(eql([experience_matrix_unique: "This criteria is already specified"]))
    end

    it "not raise error when one of the combination is different" do
      changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, valid_attrs)
      Repo.insert(changeset)
      different_changeset = ExperienceMatrix.changeset(%ExperienceMatrix{}, Map.merge(valid_attrs, %{role_id: create(:role).id}))
      {result, _} = Repo.insert(different_changeset)

      expect(result) |> to(be(:ok))
    end
  end

  context "get_interview_types_with_filter" do
    it "should return the interview types with filter" do
      Repo.delete_all ExperienceMatrix
      experience_matrix = create(:experience_matrix)

      expect(ExperienceMatrix.get_interview_types_with_filter) |> to(eq([experience_matrix.interview_type_id]))
    end

    it "should return [] if there are no interviews with filters" do
      Repo.delete_all ExperienceMatrix

      expect(ExperienceMatrix.get_interview_types_with_filter) |> to(eq([]))
    end
  end

  context "get_max_experience_with_filter" do
    it "should return maximum experience" do
      Repo.delete_all ExperienceMatrix
      create(:experience_matrix, %{panelist_experience_lower_bound: Decimal.new(90)})
      create(:experience_matrix, %{panelist_experience_lower_bound: Decimal.new(10)})
      create(:experience_matrix, %{panelist_experience_lower_bound: Decimal.new(20)})

      expect(Decimal.compare(ExperienceMatrix.get_max_experience_with_filter, Decimal.new(90))) |> to(eq(Decimal.new(0)))
    end

    it "should nil if no filters are specified" do
      Repo.delete_all ExperienceMatrix
      expect(ExperienceMatrix.get_max_experience_with_filter) |> to(eq(nil))
    end
  end

  context "should_filter_role" do
    it "should return true if the role is Dev" do
      result = Role.dev
                |> Role.retrieve_by_name
                |> ExperienceMatrix.should_filter_role

      expect(result) |> to(be(true))
    end

    it "should return true if the role is QA" do
      result = Role.qa
                |> Role.retrieve_by_name
                |> ExperienceMatrix.should_filter_role

      expect(result) |> to(be(true))
    end

    it "should return false if the role is Other" do
      result = Role.other
                |> Role.retrieve_by_name
                |> ExperienceMatrix.should_filter_role

      expect(result) |> to(be(false))
    end

    it "should return false if the role is unknown" do
      result = "unknown"
                |> Role.retrieve_by_name
                |> ExperienceMatrix.should_filter_role

      expect(result) |> to(be(false))
    end
  end
end
