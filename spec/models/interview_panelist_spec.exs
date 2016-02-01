defmodule RecruitxBackend.InterviewPanelistSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewPanelist

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Interview

  let :valid_attrs, do: fields_for(:interview_panelist)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: InterviewPanelist.changeset(%InterviewPanelist{}, valid_attrs)

    it do: should be_valid
  end

  context "invalid changeset" do
    subject do: InterviewPanelist.changeset(%InterviewPanelist{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors([panelist_login_name: "can't be blank", interview_id: "can't be blank"])

    it "should be invalid when panelist_login_name is an empty string" do
      with_empty_name = Map.merge(valid_attrs, %{panelist_login_name: ""})
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_empty_name)

      expect(changeset) |> to(have_errors([panelist_login_name: "has invalid format"]))
    end

    it "should be invalid when panelist_login_name is a blank string" do
      with_blank_name = Map.merge(valid_attrs, %{panelist_login_name: " "})
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_blank_name)

      expect(changeset) |> to(have_errors([panelist_login_name: "has invalid format"]))
    end

    it "should be invalid when panelist_login_name is nil" do
      with_nil_name = Map.merge(valid_attrs, %{panelist_login_name: nil})
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_nil_name)

      expect(changeset) |> to(have_errors([panelist_login_name: "can't be blank"]))
    end


    it "should be invalid when panelist_login_name starts with space" do
      with_nil_name = Map.merge(valid_attrs, %{panelist_login_name: " ab"})
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_nil_name)

      expect(changeset) |> to(have_errors([panelist_login_name: "has invalid format"]))
    end

    it "should be invalid when interview_id is an empty string" do
      with_empty_id = Map.merge(valid_attrs, %{interview_id: ""})
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_empty_id)

      expect(changeset) |> to(have_errors([interview_id: "is invalid"]))
    end

    it "should be invalid when interview_id is nil" do
      with_nil_id = Map.merge(valid_attrs, %{interview_id: nil})
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_nil_id)

      expect(changeset) |> to(have_errors([interview_id: "can't be blank"]))
    end
  end

  context "unique_index constraint will fail" do
    it "when same panelist is added more than once for a interview" do
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, valid_attrs)
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([panelist_login_name: "has already been taken"]))
    end
  end

  context "assoc constraint" do
    it "when candidate id not present in candidates table" do
      current_count = Ectoo.count(Repo, Interview)
      interview_id_not_present = current_count + 1
      with_invalid_interview_id = Map.merge(valid_attrs, %{interview_id: interview_id_not_present})

      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_invalid_interview_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview: "does not exist"]))
    end
  end

end
