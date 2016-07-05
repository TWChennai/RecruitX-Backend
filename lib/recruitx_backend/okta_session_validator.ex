defmodule RecruitxBackend.OktaSessionValidator do
  import Plug.Conn

  @okta_preview System.get_env("OKTA_PREVIEW")
  @okta_api_key System.get_env("OKTA_API_KEY")

  alias RecruitxBackend.JigsawController

  def init(options), do: options

  require Logger

  def call(conn, _opts) do
    conn = fetch_cookies(conn)
    session_id = conn.cookies["okta_session_id"]
    username = conn.cookies["username"]
    if !session_id || !username do
      conn |> Phoenix.Controller.redirect(to: "/login")
    end
    if !conn.cookies["calculated_hire_date"] || !conn.cookies["panelist_role"] do
      %{user_details: user_details} = JigsawController.get_jigsaw_data(username)
      conn = Plug.Conn.put_resp_cookie(conn, "calculated_hire_date", "2015-06-05")
      conn = Plug.Conn.put_resp_cookie(conn, "panelist_role", user_details.role.name)
    end
    response = HTTPotion.get(@okta_preview <> "/api/v1/sessions/" <> session_id, [headers: ["Authorization": @okta_api_key]])
    if response.status_code == 200, do: conn, else: conn |> Phoenix.Controller.redirect(to: "/login")
  end
end
