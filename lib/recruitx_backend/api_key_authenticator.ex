defmodule RecruitxBackend.ApiKeyAuthenticator do
  import Plug.Conn

  @api_key System.get_env("API_KEY")

  def init(options), do: options

  require Logger

  def call(conn, _opts) do
    api_key_header = List.first(get_req_header(conn, "authorization"))
    Logger.debug("Request header: #{api_key_header}")
    Logger.debug("System API Key: #{@api_key}")
    if @api_key == api_key_header, do: conn, else: conn |> send_resp(:unauthorized, "Invalid API key") |> halt
  end
end
