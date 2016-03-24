defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.ChangesetManipulator
  alias RecruitxBackend.ChangesetView
  alias RecruitxBackend.ErrorView
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.PipelineStatus

  # TODO: Need to fix the spec to pass context "invalid params" and check whether scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, params) do
    candidates = Candidate.get_candidates_in_fifo_order
                 |> Repo.paginate(params)
    render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => %{"skill_ids" => skill_ids, "interview_rounds" => interview_rounds} = candidate}) when skill_ids != [] and interview_rounds != [] do
      {status, result_of_db_transaction} = Repo.transaction fn ->
        try do
          {_, candidate} = [Candidate.changeset(%Candidate{}, candidate)] |> ChangesetManipulator.insert
          candidate |> generateCandidateSkillChangesets(skill_ids) |> ChangesetManipulator.insert
          candidate |> generateCandidateInterviewRoundChangesets(interview_rounds) |> ChangesetManipulator.insert
          candidate |> Repo.preload(:candidate_skills)
        catch {_, result_of_db_transaction} ->
          Repo.rollback(result_of_db_transaction)
        end
      end
      conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
  end

  def create(conn, %{"candidate" => %{"skill_ids" => skill_ids}}) when skill_ids != [] do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{interview_rounds: ["missing/empty required key"]}})
  end

  def create(conn, %{"candidate" => %{"interview_rounds" => interview_rounds}}) when interview_rounds != [] do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{skill_ids: ["missing/empty required key"]}})
  end

  def create(conn, %{"candidate" => _post_params}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{skill_ids: ["missing/empty required key"], interview_rounds: ["missing/empty required key"]}})
   end

  def show(conn, %{"id" => id}) do
    candidate = Candidate
                |> preload(:candidate_skills)
                |> Repo.get(id)
    case candidate do
      nil -> conn |> put_status(:not_found) |> render(ErrorView, "404.json")
      _ -> conn |> render("show.json", candidate: candidate)
    end
  end

  def sendResponseBasedOnResult(conn, action, status, response) do
    case {action, status} do
      {:create, :ok} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", candidate_path(conn, :show, response))
        |> json("")
      {:create, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%JSONError{errors: response})
    end
  end

  defp generateCandidateSkillChangesets(_candidate, []), do: []

  defp generateCandidateSkillChangesets(candidate, [head | tail]), do: [CandidateSkill.changeset(%CandidateSkill{}, %{candidate_id: candidate.id, skill_id: head}) | generateCandidateSkillChangesets(candidate, tail)]

  defp generateCandidateInterviewRoundChangesets(_candidate, []), do: []

  defp generateCandidateInterviewRoundChangesets(candidate, [head | tail]), do: [Interview.changeset(%Interview{}, %{candidate_id: candidate.id, interview_type_id: head["interview_type_id"], start_time: head["start_time"]}) | generateCandidateInterviewRoundChangesets(candidate, tail)]

  def update(conn, %{"id" => id, "candidate" => candidate_params}) do
    candidate = Candidate |> Repo.get(id)
    case candidate do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(ErrorView, "404.json")
      _ ->
        changeset = Candidate.changeset(candidate, candidate_params)
        case Repo.update(changeset) do
          {:ok, candidate} ->
            pipeline_status_id = candidate_params["pipeline_status_id"]
            if !is_nil(pipeline_status_id) do
              closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id
              if pipeline_status_id == closed_pipeline_status_id do
                # TODO: Combine the two following calls into a single one - and possibly push to the db
                last_completed_round_start_time = Interview.get_last_completed_rounds_start_time_for(id)
                Interview.delete_successive_interviews_and_panelists(id, last_completed_round_start_time)
              end
            end
            conn |> render("update.json", candidate: candidate)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(ChangesetView, "error.json", changeset: changeset)
        end
    end
  end
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
