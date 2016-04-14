defmodule RecruitxBackend.SosEmailController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.SosEmail

  def index(conn, _params) do
    SosEmail.execute
    conn |> put_status(:ok) |> json("")
  end
end
