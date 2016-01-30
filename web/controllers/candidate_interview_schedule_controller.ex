defmodule RecruitxBackend.CandidateInterviewScheduleController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.CandidateInterviewSchedule

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "candidate_interview_schedule" when action in [:create, :update]

  def index(conn, _params) do
    json conn, Repo.all(from cis in CandidateInterviewSchedule,
                        join: c in assoc(cis, :candidate),
                        join: r in assoc(c, :role),
                        join: s in assoc(c, :skills),
                        join: i in assoc(cis, :interview),
                        preload: [:interview, candidate: {c, role: r, skills: s}],
                        select: cis)
    # candidate_interview_schedules = Repo.all(CandidateInterviewSchedule)
    # render(conn, "index.json", candidate_interview_schedules: candidate_interview_schedules)
  end

  # def create(conn, %{"candidate_interview_schedule" => candidate_interview_schedule_params}) do
  #   changeset = CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{}, candidate_interview_schedule_params)
  #
  #   # case Repo.insert(changeset) do
  #   #   {:ok, candidate_interview_schedule} ->
  #   #     conn
  #   #     |> put_status(:created)
  #   #     |> put_resp_header("location", candidate_interview_schedule_path(conn, :show, candidate_interview_schedule))
  #   #     # |> render("show.json", candidate_interview_schedule: candidate_interview_schedule)
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
  #   candidate_interview_schedule = Repo.get!(CandidateInterviewSchedule, id)
  #   render(conn, "show.json", candidate_interview_schedule: candidate_interview_schedule)
  # end
  #
  # def update(conn, %{"id" => id, "candidate_interview_schedule" => candidate_interview_schedule_params}) do
  #   candidate_interview_schedule = Repo.get!(CandidateInterviewSchedule, id)
  #   changeset = CandidateInterviewSchedule.changeset(candidate_interview_schedule, candidate_interview_schedule_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, candidate_interview_schedule} ->
  #       render(conn, "show.json", candidate_interview_schedule: candidate_interview_schedule)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   candidate_interview_schedule = Repo.get!(CandidateInterviewSchedule, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(candidate_interview_schedule)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
