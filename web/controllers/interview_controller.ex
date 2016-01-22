defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Interview

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "interview" when action in [:create, :update]

  def index(conn, _params) do
    json conn, Repo.all(Interview)
    # interviews = Repo.all(Interview)
    # render(conn, "index.json", interviews: interviews)
  end

  # def create(conn, %{"interview" => interview_params}) do
  #   changeset = Interview.changeset(%Interview{}, interview_params)
  #
  #   # case Repo.insert(changeset) do
  #   #   {:ok, interview} ->
  #   #     conn
  #   #     |> put_status(:created)
  #   #     |> put_resp_header("location", interview_path(conn, :show, interview))
  #   #     # |> render("show.json", interview: interview)
  #   #   {:error, changeset} ->
  #   #     conn
  #   #     |> put_status(:unprocessable_entity)
  #   #     # |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   # end
  #   if changeset.valid? do
  #     Repo.insert(changeset)
  #     # TODO: Need to send JSON response
  #     send_resp(conn, 200, "")
  #   else
  #     # TODO: Need to send JSON response
  #     send_resp(conn, 400, "")
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   interview = Repo.get!(Interview, id)
  #   render(conn, "show.json", interview: interview)
  # end
  #
  # def update(conn, %{"id" => id, "interview" => interview_params}) do
  #   interview = Repo.get!(Interview, id)
  #   changeset = Interview.changeset(interview, interview_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, interview} ->
  #       render(conn, "show.json", interview: interview)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   interview = Repo.get!(Interview, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(interview)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
