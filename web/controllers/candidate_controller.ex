defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Candidate

  # TODO: Need to fix the spec to pass context "invalid params" and check scrub_params is needed
  # plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, _params) do
    json conn, Repo.all(Candidate)
    # candidates = Repo.all(Candidate)
    # render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => candidate_params}) do
    changeset = Candidate.changeset(%Candidate{}, candidate_params)

    # case Repo.insert(changeset) do
    #   {:ok, candidate} ->
    #     conn
    #     |> put_status(:created)
    #     |> put_resp_header("location", candidate_path(conn, :show, candidate))
    #     |> render("show.json", candidate: candidate)
    #   {:error, changeset} ->
    #     conn
    #     |> put_status(:unprocessable_entity)
    #     |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    # end
    if changeset.valid? do
      Repo.insert(changeset)
      # TODO: Need to send JSON response
      send_resp(conn, 200, "")
    else
      # TODO: Need to send JSON response
      send_resp(conn, 400, "")
    end
  end

  # def show(conn, %{"id" => id}) do
  #   candidate = Repo.get!(Candidate, id)
  #   render(conn, "show.json", candidate: candidate)
  # end
  #
  # def update(conn, %{"id" => id, "candidate" => candidate_params}) do
  #   candidate = Repo.get!(Candidate, id)
  #   changeset = Candidate.changeset(candidate, candidate_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, candidate} ->
  #       render(conn, "show.json", candidate: candidate)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   candidate = Repo.get!(Candidate, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(candidate)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
