defmodule RecruitxBackend.LoginController do
  use RecruitxBackend.Web, :controller

  @okta_preview System.get_env("OKTA_PREVIEW")

  def index(conn, _params) do
    conn |> render("index.html", okta_preview: @okta_preview)
  end
end
