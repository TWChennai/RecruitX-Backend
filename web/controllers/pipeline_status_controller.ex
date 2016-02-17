defmodule RecruitxBackend.PipelineStatusController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.PipelineStatus

  # plug :scrub_params, "pipeline_status" when action in [:create, :update]

  def index(conn, _params) do
    pipeline_statuses = PipelineStatus |> Repo.all
    conn |> render("index.json", pipeline_statuses: pipeline_statuses)
  end

  # def create(conn, %{"pipeline_status" => pipeline_status_params}) do
  #   changeset = PipelineStatus.changeset(%PipelineStatus{}, pipeline_status_params)
  #
  #   case Repo.insert(changeset) do
  #     {:ok, pipeline_status} ->
  #       conn
  #       |> put_status(:created)
  #       |> put_resp_header("location", pipeline_status_path(conn, :show, pipeline_status))
  #       |> render("show.json", pipeline_status: pipeline_status)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def show(conn, %{"id" => id}) do
  #   pipeline_status = Repo.get!(PipelineStatus, id)
  #   render(conn, "show.json", pipeline_status: pipeline_status)
  # end
  #
  # def update(conn, %{"id" => id, "pipeline_status" => pipeline_status_params}) do
  #   pipeline_status = Repo.get!(PipelineStatus, id)
  #   changeset = PipelineStatus.changeset(pipeline_status, pipeline_status_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, pipeline_status} ->
  #       render(conn, "show.json", pipeline_status: pipeline_status)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   pipeline_status = Repo.get!(PipelineStatus, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(pipeline_status)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
