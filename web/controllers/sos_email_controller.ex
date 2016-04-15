defmodule RecruitxBackend.SosEmailController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.SosEmail

  def index(conn, %{"get_status" => _}) do
    conn
    |> put_status(:ok)
    |> json(%{sos_validity: SosEmail.get_interviews_with_insufficient_panelists != []})
  end

  def index(conn, _params) do
    case SosEmail.execute do
      nil -> conn |> put_status(428) |> json("")
      _ -> conn |> put_status(:ok) |> json("")
    end
  end
end
