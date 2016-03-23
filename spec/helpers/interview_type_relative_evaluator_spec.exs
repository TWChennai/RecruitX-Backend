defmodule RecruitxBackend.InterviewTypeRelativeEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.InterviewTypeRelativeEvaluator

  alias RecruitxBackend.SignUpEvaluationStatus
  alias RecruitxBackend.InterviewTypeRelativeEvaluator

  context "evaluate" do
    it "should be valid when interview type has no specific panelists" do
      interview = create(:interview)

      %{valid?: validity, errors: errors}  = InterviewTypeRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, %{}, "test", interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end

    it "should be valid when panelist is one among the allowed panelists for a interview type" do
      interview = create(:interview)
      allowed_panelists = %{interview.interview_type_id => ["test"]}

      %{valid?: validity, errors: errors}  = InterviewTypeRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, allowed_panelists, "test", interview)

      expect(validity) |> to(be_true)
      expect(errors) |> to(be([]))
    end

    it "should be invalid when panelist is not one among the allowed panelists for a interview type" do
      interview = create(:interview)
      allowed_panelists = %{interview.interview_type_id => ["testing"]}

      %{valid?: validity, errors: errors}  = InterviewTypeRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, allowed_panelists, "test", interview)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "You are not eligible to sign up for this interview"]))
    end

    it "should be invalid when panelist is not one among the allowed panelists for a interview type but for a different interview type" do
      interview = create(:interview)
      allowed_panelists = %{interview.interview_type_id => ["testing"], create(:interview_type) => ["test"]}

      %{valid?: validity, errors: errors}  = InterviewTypeRelativeEvaluator.evaluate(%SignUpEvaluationStatus{}, allowed_panelists, "test", interview)

      expect(validity) |> to(be_false)
      expect(errors) |> to(be([signup: "You are not eligible to sign up for this interview"]))
    end
  end
end
