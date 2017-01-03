defmodule RecruitxBackend.WeekendDriveController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.WeekendDrive
  alias RecruitxBackend.ErrorView

  plug :scrub_params, "weekend_drive" when action in [:create, :update]

   def index(conn, _params) do
     weekend_drives = Repo.all(WeekendDrive)
     render(conn, "index.json", weekend_drives: weekend_drives)
   end

  def create(conn, %{"weekend_drive" => weekend_drive_params}) do
    changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_params)

    case Repo.insert(changeset) do
      {:ok, weekend_drive} ->
        conn
        |> put_status(:created)
        # |> put_resp_header("location", weekend_drive_path(conn, :show, weekend_drive))
        |> render("show.json", weekend_drive: weekend_drive)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end

   def show(conn, %{"id" => id}) do
     weekend_drive = Repo.get(WeekendDrive, id)
     case weekend_drive do
       nil -> conn |> put_status(:not_found) |> render(ErrorView, "404.json")
       _ -> render(conn, "show.json", weekend_drive: weekend_drive)
     end
   end

   def update(conn, %{"id" => id, "weekend_drive" => weekend_drive_params}) do
     weekend_drive = Repo.get(WeekendDrive, id)
     case weekend_drive do
       nil -> conn |> put_status(:not_found) |> render(ErrorView,"404.json")
       _ ->
         changeset = WeekendDrive.changeset(weekend_drive, weekend_drive_params)
         case Repo.update(changeset) do
           {:ok, weekend_drive} -> render(conn, "show.json", weekend_drive: weekend_drive)
           {:error, changeset} ->
             conn |> put_status(:unprocessable_entity) |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
         end
     end
   end

#   def delete(conn, %{"id" => id}) do
#     weekend_drive = Repo.get(WeekendDrive, id)
#     case weekend_drive do
#       nil -> conn |> put_status(:not_found) |> render(ErrorView,"404.json")
#       _ -> Repo.delete!(weekend_drive)
#     end
#     send_resp(conn, :no_content, "")
#   end
end
