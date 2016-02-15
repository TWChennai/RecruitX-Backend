defmodule RecruitxBackend.InterviewStatusController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewStatus

  # TODO: Uncomment if/when implementing the create/update actions
  #plug :scrub_params, "interview_status" when action in [:create, :update]

  def index(conn, _params) do
    interview_status = InterviewStatus |> Repo.all
    conn |> render("index.json", interview_status: interview_status)
  end

  #def create(conn, %{"interview_status" => interview_status_params}) do
  #  changeset = InterviewStatus.changeset(%InterviewStatus{}, interview_status_params)

  #  case Repo.insert(changeset) do
  #    {:ok, interview_status} ->
  #      conn
  #      |> put_status(:created)
  #      |> put_resp_header("location", interview_status_path(conn, :show, interview_status))
  #      |> render("show.json", interview_status: interview_status)
  #    {:error, changeset} ->
  #      conn
  #      |> put_status(:unprocessable_entity)
  #      |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #  end
  #end

  #def show(conn, %{"id" => id}) do
  #  interview_status = Repo.get!(InterviewStatus, id)
  #  render(conn, "show.json", interview_status: interview_status)
  #end

  #def update(conn, %{"id" => id, "interview_status" => interview_status_params}) do
  #  interview_status = Repo.get!(InterviewStatus, id)
  #  changeset = InterviewStatus.changeset(interview_status, interview_status_params)

  #  case Repo.update(changeset) do
  #    {:ok, interview_status} ->
  #      render(conn, "show.json", interview_status: interview_status)
  #    {:error, changeset} ->
  #      conn
  #      |> put_status(:unprocessable_entity)
  #      |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #  end
  #end

  #def delete(conn, %{"id" => id}) do
  #  interview_status = Repo.get!(InterviewStatus, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
  #  Repo.delete!(interview_status)

  #  send_resp(conn, :no_content, "")
  #end
end
