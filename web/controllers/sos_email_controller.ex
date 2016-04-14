defmodule RecruitxBackend.SosEmailController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.SosEmail

  def create(conn, _params) do
    SosEmail.execute
    conn |> put_status(:ok)
  end
end
