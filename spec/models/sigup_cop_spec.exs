defmodule RecruitxBackend.SignupCopSpec do
  use ESpec.Phoenix, model: RecruitxBackend.SignupCop

  alias RecruitxBackend.SignupCop

  context "is_signup_cop" do
    it "should return true if it present in db" do
      true_cop = "true_cop"
      insert(:signup_cop, name: true_cop)

      expect(SignupCop.is_signup_cop(true_cop)) |> to(be(true))
      expect(SignupCop.is_signup_cop("false_cop")) |> to(be(false))
    end
  end
end
