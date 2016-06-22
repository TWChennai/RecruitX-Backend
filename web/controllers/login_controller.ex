defmodule RecruitxBackend.LoginController do
  use RecruitxBackend.Web, :controller

  @okta_preview System.get_env("OKTA_PREVIEW")
  @api_key System.get_env("API_KEY")

  def index(conn, _params) do
    if @okta_preview, do: render(conn,"index.html", okta_preview: @okta_preview, api_key: @api_key), else: conn |> send_resp(:not_found, "Invalid Okta Url") |> halt
  end
end
