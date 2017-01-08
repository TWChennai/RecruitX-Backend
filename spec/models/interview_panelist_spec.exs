defmodule RecruitxBackend.InterviewPanelistSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewPanelist

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo
  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.SignUpEvaluator
  alias RecruitxBackend.TimexHelper

  let :valid_attrs, do: fields_for(:interview_panelist)
  let :invalid_attrs, do: %{}
  let :role, do: create(:role)

  before do: Repo.delete_all(Interview)
  before do: allow SignUpEvaluator |> to(accept(:evaluate, fn(_, _, _) ->  %SignUpEvaluationStatus{satisfied_criteria: "LB"} end))

  context "valid changeset" do
    subject do: InterviewPanelist.changeset(%InterviewPanelist{}, convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{panelist_experience: 2, panelist_role: role.name})))

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

    it "should be invalid when sign up evaluation is invalid" do
      invalid = %SignUpEvaluationStatus{valid?: false, errors: [error: "errors"]}
      allow SignUpEvaluator |> to(accept(:evaluate, fn(_, _, _) ->  invalid end))

      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{panelist_experience: 2, panelist_role: role.name})))

      expect(changeset) |> to(have_errors([error: "errors"]))
    end
  end

  context "unique_index constraint" do
    it "should not allow same panelist to be added more than once for same interview" do
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{panelist_experience: 2, panelist_role: role.name})))
      Repo.insert(changeset)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([panelist_login_name: "You have already signed up for this interview"]))
    end

    it "should allow same panelist to be added more than once for a different interview" do
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{panelist_experience: 2, panelist_role: role.name})))
      Repo.insert(changeset)
      signed_up_interview = Interview |> Repo.get(valid_attrs.interview_id)
      new_interview = create(:interview, start_time: signed_up_interview.start_time |> TimexHelper.add(2, :hours))
      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{interview_id: new_interview.id, panelist_experience: 2, panelist_role: role.name})))

      {status, _} = Repo.insert(changeset)

      expect(status) |> to(eql(:ok))
    end
  end

  context "assoc constraint" do
    it "when candidate id not present in candidates table" do
      interview_id_not_present = -1
      with_invalid_interview_id = convertKeysFromAtomsToStrings(Map.merge(valid_attrs, convertKeysFromAtomsToStrings(%{interview_id: interview_id_not_present, panelist_experience: 2, panelist_role: role.name})))

      changeset = InterviewPanelist.changeset(%InterviewPanelist{}, with_invalid_interview_id)

      {:error, error_changeset} = Repo.insert(changeset)
      expect(error_changeset) |> to(have_errors([interview: "Interview does not exist"]))
    end
  end

  describe "query" do
    context "get_signup_count_for_interview_id" do
      it "should return nil when there are no signups" do
        result = InterviewPanelist.get_signup_count_for_interview_id(-1) |> Repo.one

        expect(result) |> to(eql(nil))
      end

      it "should return 1 when there is a signup" do
        interview_panelist = create(:interview_panelist)
        result = InterviewPanelist.get_signup_count_for_interview_id(interview_panelist.interview_id) |> Repo.one

        expect(result) |> to(eql(1))
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

    context "get_interviews_signed_up_by" do
      it "should give the interviews for the requested panelist" do
        panelist_login_name = "recruitx"
        interview_panelist = create(:interview_panelist, panelist_login_name: panelist_login_name)
        preloaded_interview = Interview
                                |> preload([:interview_panelist, candidate: :candidate_skills])
                                |> Repo.get(interview_panelist.interview_id)

        response = InterviewPanelist.get_interviews_signed_up_by(panelist_login_name) |> Repo.all

        expect(response) |> to(be([preloaded_interview]))
      end
    end
  end
end
