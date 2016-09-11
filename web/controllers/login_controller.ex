defmodule RecruitxBackend.LoginController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.JigsawController
  alias Timex.DateFormat
  alias Plug.Conn

  @invalid_user "not a valid user"
  @time_out_error "Jigsaw API failed to respond, please try again later"

  def index(conn, %{"username" => username}) do
    %{user_details: user_details} = JigsawController.get_jigsaw_data(username)
    if user_details.error != @invalid_user && user_details.error != @time_out_error do
      hire_date = DateFormat.format!(user_details.calculated_hire_date, "%Y-%m-%d", :strftime)
      conn = Conn.put_resp_cookie(conn, "username", username, http_only: false)
      conn = Conn.put_resp_cookie(conn, "calculated_hire_date", hire_date, http_only: false)
      conn = Conn.put_resp_cookie(conn, "panelist_role", user_details.role.name, http_only: false)
      conn |> redirect(to: "/my_interviews")
    else
      conn |> render("index.html",error: "Something went wrong! Please try again later!", not_login: false)
    end
  end

  def index(conn, _params) do
    conn |> render("index.html",error: "", not_login: false)
  end
end
