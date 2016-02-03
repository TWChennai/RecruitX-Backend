defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.QueryFilter

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "interview" when action in [:create, :update]

  def index(conn, params) do
    interviews = (from cis in Interview,
                  join: c in assoc(cis, :candidate),
                  join: cs in assoc(c, :candidate_skills),
                  join: i in assoc(cis, :interview_type),
                  preload: [:interview_type, candidate: {c, [candidate_skills: cs]}],
                  select: cis) |> QueryFilter.filter(%Interview{}, params, [:candidate_id]) |> Repo.all

    interviewWithSignupStatus = addSignUpEigibityFor(interviews, params["panelist_login_name"])
    render(conn, "index.json", interviews: interviewWithSignupStatus)
  end

  def show(conn, %{"id" => id}) do
    interview = (from i in Interview,
      join: c in assoc(i, :candidate),
      join: cs in assoc(c, :candidate_skills),
      join: it in assoc(i, :interview_type),
      preload: [:interview_type, candidate: {c, candidate_skills: cs}],
      select: i) |> Repo.get(id)
    render(conn, "show.json", interview: interview)
  end

  def addSignUpEigibityFor(interviews, panelist_login_name) do
    candidate_ids_interviewed = Interview.getCandidateIdsInterviewedBy(panelist_login_name) |> Repo.all
    Enum.map(interviews, fn(interview) ->
      Map.put(interview, :sign_up, hasPanelistNotInterviewedCandidate(candidate_ids_interviewed, interview))
    end)
  end

  def hasPanelistNotInterviewedCandidate(candidate_ids_interviewed, interview) do
    !Enum.member?(candidate_ids_interviewed, interview.candidate_id)
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
