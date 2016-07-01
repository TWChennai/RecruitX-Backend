defmodule RecruitxBackend.LoginController do
  use RecruitxBackend.Web, :controller

  @okta_preview System.get_env("OKTA_PREVIEW")
  @api_url System.get_env("API_URL")

  alias RecruitxBackend.JigsawController

  def index(conn = %Plug.Conn{cookies: %{"username" => panelist_login_name}}, _params) do
    conn = Plug.Conn.put_resp_cookie(conn, "calculated_hire_date", "dummy_date")
    conn = Plug.Conn.put_resp_cookie(conn, "panelist_role", "Dev")
    conn |> redirect to: "/web/"
  end

  def index(conn, _params) do
    if @okta_preview, do: render(conn,"index.html", okta_preview: @okta_preview, api_url: @api_url), else: conn |> send_resp(:not_found, "Invalid Okta Url") |> halt
  end
end
