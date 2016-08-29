defmodule RecruitxBackend.LoginController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.JigsawController
  alias Timex.DateFormat
  alias Plug.Conn

  def index(conn = %Plug.Conn{cookies: %{"username" => username}}, _params) do
    %{user_details: user_details} = JigsawController.get_jigsaw_data(username)
    hire_date = DateFormat.format!(user_details.calculated_hire_date, "%Y-%m-%d", :strftime)
    conn = Conn.put_resp_cookie(conn, "calculated_hire_date", hire_date, http_only: false)
    conn = Conn.put_resp_cookie(conn, "panelist_role", user_details.role.name, http_only: false)
    conn |> redirect(to: "/homepage")
  end

  def index(conn, _params) do
    conn |> render("index.html",error: "")
  end
end
