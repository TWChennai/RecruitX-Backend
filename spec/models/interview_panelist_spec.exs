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

  context "unique_index constraint" do
    it "should not allow same panelist to be added more than once for same interview" do
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, valid_attrs)
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([panelist_login_name: "has already been taken"]))
    end

    it "should allow same panelist to be added more than once for a different interview" do
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, valid_attrs)
      Repo.insert(changeset)
      new_interview = create(:interview)
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, Map.merge(valid_attrs, %{interview_id: new_interview.id}))
      {status, _} = Repo.insert(changeset)
      expect(status) |> to(eql(:ok))
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

  context "get_interview_type_based_count_of_sign_ups" do
    it "should return {interview_id, count_of_signups, interview_type_id" do
      result = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all

      expect(result) |> to(eql([]))
    end

    it "should return {interview_id, count_of_signups, interview_type_id}" do
      interview = create(:interview)
      interview_panelist = create(:interview_panelist, interview_id: interview.id)
      [result] = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all
      %{"interview_id": interview_id,"signup_count": count_of_signups,"interview_type": type_id} = result
      expect(interview_id) |> to(eql(interview_panelist.interview_id))
      expect(count_of_signups) |> to(eql(1))
      expect(type_id) |> to(eql(interview.interview_type_id))
    end
  end
end
