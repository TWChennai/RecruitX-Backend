defmodule RecruitxBackend.ApiKeyAuthenticatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.ApiKeyAuthenticator

  import Phoenix.ConnTest
  import Plug.Conn

  alias RecruitxBackend.ApiKeyAuthenticator

  describe "api key authentication" do
    it "should return 401 and not process request if authorization header is not present" do
      response = ApiKeyAuthenticator.call(build_conn(), :empty)

      expect(response.status) |> to(be(401))
      expect(response.resp_body) |> to(be("Invalid API key"))
    end

    it "should return 401 and not process request if API key is invalid" do
      conn = put_req_header(build_conn(), "authorization", "invalid")
      response = ApiKeyAuthenticator.call(conn, :empty)
      expect(response.status) |> to(be(401))
      expect(response.resp_body) |> to(be("Invalid API key"))
    end

    it "should return conn to process request if API key is valid" do
      conn = put_req_header(build_conn(), "authorization", System.get_env("API_KEY"))
      response = ApiKeyAuthenticator.call(conn, :empty)

      expect(response) |> to(be(conn))
    end
  end
end
