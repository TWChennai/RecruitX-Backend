defmodule RecruitxBackend.OktaSessionValidatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.OktaSessionValidator

  import Phoenix.ConnTest
  import Plug.Conn

  alias RecruitxBackend.OktaSessionValidator

  describe "api key authentication" do
    it "should redirect to the login page when there is no session_id and no user name" do
      response = OktaSessionValidator.call(conn_with_dummy_authorization(), :empty)

      expect(response.status) |> to(be(302))
    end
  end
end
