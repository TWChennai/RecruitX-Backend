defmodule RecruitxBackend.OktaSessionValidatorSpec do
  use ESpec.Phoenix, model: RecruitxBackend.OktaSessionValidator

  import Phoenix.ConnTest
  import Plug.Conn

  alias RecruitxBackend.OktaSessionValidator

  xdescribe "api key authentication" do

    it "should redirect to the login page when there is no session_id and no user name" do
      response = OktaSessionValidator.call(conn_with_dummy_authorization(), :empty)

      expect(response.status) |> to(be(302))
    end

    it "if all the cookies exists the session is not valid it should redirect to the login" do
      conn = conn_with_dummy_authorization()
      conn = Plug.Conn.put_resp_cookie(conn, "username", "ppanalist", http_only: false)
      conn = Plug.Conn.put_resp_cookie(conn, "okta_session_id", "dummy_session_id", http_only: false)
      conn = Plug.Conn.put_resp_cookie(conn, "calculated_hire_date", "2015-06-05", http_only: false)
      conn = Plug.Conn.put_resp_cookie(conn, "panelist_role", "Dev", http_only: false)

      response = OktaSessionValidator.call(conn, :empty)
      IO.inspect response
      expect(response.status) |> to(be(302))
    end

    it "if calculated_hire_date and panelist_role cookie are not set then jigsaw controller should set it" do
      conn = conn_with_dummy_authorization()
      conn = Plug.Conn.put_resp_cookie(conn, "username", "ppanelist", http_only: false)
      conn = Plug.Conn.put_resp_cookie(conn, "okta_session_id", "dummy_session_id", http_only: false)

      response = OktaSessionValidator.call(conn, :empty)

      expect(response.status) |> to(be(302))
      expect(response.cookies["panelist_role"] |> to(be("Dev")))
      expect(response.cookies["calculated_hire_date"] |> should_not(be(nil)))
    end

  end
end
