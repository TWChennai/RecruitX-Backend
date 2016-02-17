defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.ChangesetManipulator

  # TODO: Need to fix the spec to pass context "invalid params" and check scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, _) do
    candidates = Candidate.get_candidates_in_fifo_order
                 |> Repo.all
    render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => post_params}) do
    try do
      skill_ids = "skill_ids" |> readQueryParamOrRaiseError(post_params)
      interview_rounds = "interview_rounds" |> readQueryParamOrRaiseError(post_params)
      # TODO: Need to remove the try-rescue block
      {status, result_of_db_transaction} = Repo.transaction fn ->
        try do
          {_, candidate} = [Candidate.changeset(%Candidate{}, post_params)] |> ChangesetManipulator.insertChangesets
          candidate |> generateCandidateSkillChangesets(skill_ids) |> ChangesetManipulator.insertChangesets
          candidate |> generateCandidateInterviewRoundChangesets(interview_rounds) |> ChangesetManipulator.insertChangesets
          candidate |> Repo.preload(:candidate_skills)
        catch {_, result_of_db_transaction} ->
          Repo.rollback(result_of_db_transaction)
        end
      end
      conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
    catch {:missing_param_error, key} ->
      conn |> sendResponseBasedOnResult(:create, :error, [%JSONErrorReason{field_name: key, reason: "missing/empty required key"}])
    end
  end

  def show(conn, %{"id" => id}) do
    candidate = Candidate
                |> preload(:candidate_skills)
                |> Repo.get(id)
    case candidate do
      nil -> conn |> put_status(:not_found) |> render(RecruitxBackend.ErrorView, "404.json")
      _ -> conn |> render("show.json", candidate: candidate)
    end
  end

  defp readQueryParamOrRaiseError(key, post_params) do
    read_query_params = post_params[key]
    # TODO: Do not 'throw' return a tuple with an error code
    if !read_query_params || Enum.empty?(read_query_params), do: throw {:missing_param_error, key}
    read_query_params |> Enum.uniq
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

  defp generateCandidateSkillChangesets(candidate, skill_ids) do
    # TODO: Use 'Ecto.build_assoc' instead of this
    #Ecto.build_assoc generates a model which should be cast to a changeset,which doesn't hold errors before insertion to database
    for n <- skill_ids, do: CandidateSkill.changeset(%CandidateSkill{}, %{candidate_id: candidate.id, skill_id: n})
  end

  defp generateCandidateInterviewRoundChangesets(candidate, interview_rounds) do
    for single_round <- interview_rounds, do:
      Interview.changeset(%Interview{},
        %{candidate_id: candidate.id, interview_type_id: single_round["interview_type_id"], start_time: single_round["start_time"]})
  end

  def update(conn, %{"id" => id, "candidate" => candidate_params}) do
    candidate = Candidate |> Repo.get(id)
    case candidate do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(RecruitxBackend.ErrorView, "404.json")
      _ ->
        changeset = Candidate.changeset(candidate, candidate_params)
        case Repo.update(changeset) do
          {:ok, candidate} ->
            conn |> render("update.json", candidate: candidate)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
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
