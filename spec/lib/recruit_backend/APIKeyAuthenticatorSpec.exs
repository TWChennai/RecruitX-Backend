defmodule RecruitxBackend.API_Key_AuthenticatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.API_Key_Authenticator

  import Phoenix.ConnTest
  import Plug.Conn

  alias RecruitxBackend.API_Key_Authenticator

  require Logger

  describe "api key authentication" do
    it "should return 401 and not process request if authorization header is not present" do
      response = API_Key_Authenticator.call(conn(), :empty)

      expect(response.status) |> to(be(401))
      expect(response.resp_body) |> to(be("Invalid API key"))
    end

    it "should return 401 and not process request if API key is invalid" do
      conn = put_req_header(conn(), "authorization", "invalid")
      response = API_Key_Authenticator.call(conn, :empty)
      expect(response.status) |> to(be(401))
      expect(response.resp_body) |> to(be("Invalid API key"))
    end

    it "should return conn to process request if API key is valid" do
      conn = put_req_header(conn(), "authorization", "recruitx")
      response = API_Key_Authenticator.call(conn, :empty)

      expect(response) |> to(be(conn))
    end
  end
end
