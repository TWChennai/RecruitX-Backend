defmodule RecruitxBackend.SosEmailControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SosEmailController

  alias RecruitxBackend.SosEmail

  describe "index" do
    it "should send a sos email" do
      allow SosEmail |> to(accept(:execute, fn() -> "" end))
      conn = action(:index, %{})

      conn |> should(have_http_status(:ok))
      expect SosEmail |> to(accepted :execute)
    end
  end
end
