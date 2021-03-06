defmodule RecruitxBackend.SignUpEvaluatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.SignUpEvaluator

  alias Decimal
  alias RecruitxBackend.InterviewRelativeEvaluator
  alias RecruitxBackend.InterviewTypeRelativeEvaluator
  alias RecruitxBackend.ExperienceMatrixRelativeEvaluator
  alias RecruitxBackend.Role
  alias RecruitxBackend.SignUpEvaluator

  let :interview, do: insert(:interview)

  before do
    allow InterviewRelativeEvaluator |> to(accept :evaluate)
    allow InterviewTypeRelativeEvaluator |> to(accept :evaluate)
    allow ExperienceMatrixRelativeEvaluator |> to(accept :evaluate)
  end

  describe "evaluate" do
    it "should not call rolewise and experience matrix evaluator when the panelist role is OPs" do
      ops_role = Role.retrieve_by_name(Role.ops)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container("test", Decimal.new(1), ops_role)

      SignUpEvaluator.evaluate(sign_up_data_container, interview(), [])

      expect InterviewRelativeEvaluator |> to(accepted :evaluate)
      expect InterviewTypeRelativeEvaluator |> to_not(accepted :evaluate)
      expect ExperienceMatrixRelativeEvaluator |> to_not(accepted :evaluate)
    end

    it "should all evaluators when the panelist role is not OPs" do
      role = insert(:role)
      sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container("test", Decimal.new(1), role)
      SignUpEvaluator.evaluate(sign_up_data_container, interview(), [])

      expect InterviewRelativeEvaluator |> to(accepted :evaluate)
      expect ExperienceMatrixRelativeEvaluator |> to(accepted :evaluate)
      expect InterviewTypeRelativeEvaluator |> to(accepted :evaluate)
    end
  end
end
