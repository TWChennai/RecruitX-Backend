defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.ChangesetInserter

  # TODO: Need to fix the spec to pass context "invalid params" and check scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, params) do
    candidates = Candidate
                  |> preload(:candidate_skills)
                  |> QueryFilter.filter(%Candidate{}, params, [:name, :role_id])
                  |> Repo.all
    render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => post_params}) do
    try do
      skill_ids = readQueryParamOrRaiseError("skill_ids", post_params)
      interview_rounds = readQueryParamOrRaiseError("interview_rounds", post_params)
      # TODO: Need to remove the try-rescue block
      {status, result_of_db_transaction} = Repo.transaction fn ->
        try do
          candidate_changesets = Candidate.changeset(%Candidate{}, post_params)
          {_, candidate} = ChangesetInserter.insertChangesets([candidate_changesets])

          candidate_skill_changesets = generateCandidateSkillChangesets(candidate, skill_ids)
          ChangesetInserter.insertChangesets(candidate_skill_changesets)

          candidate_interview_rounds_changeset = generateCandidateInterviewRoundChangesets(candidate, interview_rounds)
          ChangesetInserter.insertChangesets(candidate_interview_rounds_changeset)
          Repo.preload(candidate, :candidate_skills)
        catch {_, result_of_db_transaction} ->
          Repo.rollback(result_of_db_transaction)
        end
      end
      sendResponseBasedOnResult(conn, :create, status, result_of_db_transaction)
    catch {:missing_param_error, key} ->
      sendResponseBasedOnResult(conn, :create, :error, [%JSONErrorReason{field_name: key, reason: "missing/empty required key"}])
    end
  end

  def show(conn, %{"id" => id}) do
    candidate = Candidate
                |> preload(:candidate_skills)
                |> Repo.get(id)
    if candidate != nil do
      render(conn, "show.json", candidate: candidate)
    else
      render(conn, RecruitxBackend.ErrorView, "404.json")
    end
  end

  defp readQueryParamOrRaiseError(key, post_params) do
    read_query_params = post_params[key]
    # TODO: Do not 'throw' return a tuple with an error code
    if !read_query_params || Enum.empty?(read_query_params), do: throw {:missing_param_error, key}
    Enum.uniq(read_query_params)
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
