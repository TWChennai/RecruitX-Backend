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

  def show(conn, %{"id" => id}) do
    slot = Slot |> Repo.get(id)
    case slot do
      nil -> conn
            |> put_status(:not_found)
            |> render(ErrorView, "404.json")
      _ -> conn
          |> render("show.json", slot: slot)
    end
  end

  def index(conn, %{"interview_type_id" => interview_type_id, "previous_rounds_start_time" => previous_rounds_start_time, "role_id" => role_id}) do
    previous_rounds_end_time = previous_rounds_start_time
                                |> DateFormat.parse!("%Y-%m-%dT%H:%M:%SZ", :strftime)
                                |> Date.shift(hours: 1)
    slots = (from s in Slot,
            where: s.interview_type_id == ^interview_type_id and
            s.role_id == ^role_id and
            s.start_time >= ^previous_rounds_end_time)
            |> Repo.all
    conn |> render("index.json", slots: slots)
  end

end
