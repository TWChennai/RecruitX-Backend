defmodule RecruitxBackend.SlotController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Slot

  # plug :scrub_params, "slot" when action in [:create, :update]

  def create(conn, %{"slot" => %{"count" => count} = slot_params}) do
    create_multiple_slots(conn, Slot.changeset(%Slot{}, slot_params), count)
  end


  defp create_multiple_slots(conn, changeset, 1) do
    case Repo.insert(changeset) do
      {:ok, slot} ->
        conn
        |> put_status(:created)
        |> render("show.json", slot: slot)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp create_multiple_slots(conn, changeset, count) do
    case Repo.insert(changeset) do
      {:ok, _slot} ->
        create_multiple_slots(conn, changeset, count - 1)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end

end
