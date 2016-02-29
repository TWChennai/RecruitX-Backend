defmodule RecruitxBackend.APIKeyAuthenticatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.APIKeyAuthenticator

  import Phoenix.ConnTest
  import Plug.Conn

  alias RecruitxBackend.APIKeyAuthenticator

  describe "api key authentication" do
    it "should return 401 and not process request if authorization header is not present" do
      response = APIKeyAuthenticator.call(conn(), :empty)

      expect(response.status) |> to(be(401))
      expect(response.resp_body) |> to(be("Invalid API key"))
    end

    it "should return 401 and not process request if API key is invalid" do
      conn = put_req_header(conn(), "authorization", "invalid")
      response = APIKeyAuthenticator.call(conn, :empty)

      expect(response.status) |> to(be(401))
      expect(response.resp_body) |> to(be("Invalid API key"))
    end

    it "should return conn to process request if API key is valid" do
      conn = put_req_header(conn(), "authorization", "recruitx")
      response = APIKeyAuthenticator.call(conn, :empty)

      expect(response) |> to(be(conn))
    end
  end
end
