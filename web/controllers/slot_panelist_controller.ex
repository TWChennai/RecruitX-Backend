defmodule RecruitxBackend.SlotPanelistController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.SlotPanelist

  def create(conn, %{"slot_panelist" => slot_panelist_params}) do
    changeset = SlotPanelist.changeset(%SlotPanelist{}, slot_panelist_params)

    case Repo.insert(changeset) do
      {:ok, slot_panelist} ->
        conn
        |> put_status(:created)
        |> render("show.json", slot_panelist: slot_panelist)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
