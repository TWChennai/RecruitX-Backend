defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.CandidateInterviewSchedule
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.QueryFilter

  # TODO: Need to fix the spec to pass context "invalid params" and check scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, params) do
    candidates = Candidate
                  |> preload(:role)
                  |> QueryFilter.filter(%Candidate{}, params, [:name, :role_id])
                  |> Repo.all
    json conn, candidates
    # render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => post_params}) do
    skill_ids = readQueryParamOrRaiseError("skill_ids", post_params)
    interview_rounds = readQueryParamOrRaiseError("interview_rounds", post_params)
    {status, result_of_db_transaction} = Repo.transaction fn ->
      try do
        {_, candidate} = insertCandidate(post_params)
        candidate_skill_changesets = generateCandidateSkillChangesets(candidate, skill_ids)
        insertChangesets(candidate_skill_changesets)

        candidate_interview_rounds_changeset = generateCandidateInterviewRoundChangesets(candidate, interview_rounds)
        insertChangesets(candidate_interview_rounds_changeset)
        Repo.preload candidate, :role
      catch {_, result_of_db_transaction} ->
        Repo.rollback(result_of_db_transaction)
      end
    end
    sendResponseBasedOnResult(conn, :create, status, result_of_db_transaction)
  end

  defp readQueryParamOrRaiseError(key, post_params) do
    read_query_params = post_params[key]
    # TODO: API call should not raise an error. The exception should be converted to JSON and sent with valid reponse status code
    # otherwise, it will show up as "500 internal server error"
    if !read_query_params || Enum.empty?(read_query_params), do: raise Phoenix.MissingParamError, key: key
    Enum.uniq(read_query_params)
  end

  def sendResponseBasedOnResult(conn, action, status, response) do
    case {action, status} do
      {:create, :ok} ->
        conn
          |> put_status(:created)
          |> put_resp_header("location", candidate_path(conn, :show, response))
          |> json(response)
      {:create, _} ->
        conn
          |> put_status(:unprocessable_entity)
          |> json(%JSONError{errors: response})
    end
  end

  def getCandidateProfileParams(post_params) do
    QueryFilter.cast(%Candidate{}, post_params, [:name, :role_id, :experience, :additional_information])
  end

  def getChangesetErrorsInReadableFormat(changeset) do
    if Map.has_key?(changeset, :errors) do
      for n <- Keyword.keys(changeset.errors) do
        value = Keyword.get(changeset.errors, n)
        if is_tuple(value) do
          value = elem(value, 0)
        end
        %JSONErrorReason{field_name: n, reason: value}
      end
    else
      []
    end
  end

  defp insertCandidate(post_params) do
    candidate_changeset = Candidate.changeset(%Candidate{}, getCandidateProfileParams(post_params))
    if candidate_changeset.valid? do
      {status, candidate} = Repo.insert(candidate_changeset)
      if (status == :error) do
        throw {status, getChangesetErrorsInReadableFormat(candidate)}
      else
        {status, candidate}
      end
    else
      throw {:changeset_error, getChangesetErrorsInReadableFormat(candidate_changeset)}
    end
  end

  defp generateCandidateSkillChangesets(candidate, skill_ids) do
    # TODO: Use 'Ecto.build_assoc' instead of this
    for n <- skill_ids, do: CandidateSkill.changeset(%CandidateSkill{}, %{candidate_id: candidate.id, skill_id: n})
  end

  defp generateCandidateInterviewRoundChangesets(candidate, interview_rounds) do
    for single_round <- interview_rounds, do:
      CandidateInterviewSchedule.changeset(%CandidateInterviewSchedule{},
        %{candidate_id: candidate.id, interview_id: single_round["interview_id"], candidate_interview_date_time: single_round["interview_date_time"]})
  end

  defp insertChangesets(changesets) do
    result = Enum.all?(changesets, fn(changeset) ->
      changeset.valid?
    end)
    if result do
      {status, changeset} = Enum.reduce_while(changesets, [], fn i, _ ->
        {status, result} = Repo.insert(i)
        acc = {status, result}
        if (status == :error) do
          throw {status, getChangesetErrorsInReadableFormat(result)}
        else
          {:cont, acc}
        end
      end)
    else
      errors = for n <- changesets, do: List.first(getChangesetErrorsInReadableFormat(n))
      errors_without_nil_values = Enum.filter(errors, fn(error) -> error != nil end)
      throw ({:changeset_error, errors_without_nil_values})
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
