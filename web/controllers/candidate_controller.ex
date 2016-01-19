defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError


  # TODO: Need to fix the spec to pass context "invalid params" and check scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, _params) do
    json conn, Repo.all(Candidate)
    # candidates = Repo.all(Candidate)
    # render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => post_params}) do
    skill_ids = readQueryParamOrRaiseError("skill_ids", post_params)
    {status, result_of_db_transaction} = Repo.transaction fn ->
      candidate_skill_insertion_status = :error
      {candidate_insertion_status, result_of_db_transaction} = insertCandidate(post_params)

      if candidate_insertion_status == :ok do
          {candidate_skill_insertion_status, result_of_db_transaction} = insertCandidateSkills(result_of_db_transaction, skill_ids)
      end

      #Error by changeset validation before db insertion
      if candidate_insertion_status == :changeset_error || candidate_skill_insertion_status == :changeset_error do
        Repo.rollback(result_of_db_transaction)
      end

      #Error while inserting into db like forein keys do not exist error
      if candidate_insertion_status == :error  || candidate_skill_insertion_status == :error do
        Repo.rollback(getChangesetErrorsInReadableFormat(result_of_db_transaction))
      end
      #TODO: Sending errors in json format instead of strings
    end
    sendResponseBasedOnResult(conn, status, result_of_db_transaction)
  end

  def readQueryParamOrRaiseError(key, post_params) do
    read_query_params = post_params[key]
    unless read_query_params  && Enum.count(read_query_params) != 0 do
      raise Phoenix.MissingParamError, key: key
    end
    Enum.uniq(read_query_params)
  end

  def insertCandidate(post_params) do
    candidate_changeset = Candidate.changeset(%Candidate{}, getCandidateProfileParams(post_params))
    if candidate_changeset.valid? do
      {status, candidate} = Repo.insert(candidate_changeset)
    else
      {:changeset_error,getChangesetErrorsInReadableFormat(candidate_changeset)}
    end
  end

  def insertCandidateSkills(candidate, skill_ids) do
    candidate_skill_changesets = for n <- skill_ids, do: CandidateSkill.changeset(%CandidateSkill{}, %{candidate_id: candidate.id, skill_id: n})
    result = Enum.all?(candidate_skill_changesets, fn(changeset) ->
      changeset.valid?
    end)
    if result do
      {status,changeset} = Enum.reduce_while(candidate_skill_changesets, [], fn i, acc ->
        {status, result} = Repo.insert(i)
        acc = {status, result}
        if( status == :error) do
          {:halt, acc}
        else
          {:cont, acc}
        end
      end)
    else
      errors = for n <- candidate_skill_changesets, do: List.first(getChangesetErrorsInReadableFormat(n))
      {:changeset_error, errors}
    end
  end

  def sendResponseBasedOnResult(conn, status, response) do
    if status == :ok do
      conn
        |> put_status(200)
        |> json(response)
    else
      conn
        |> put_status(400)
        |> json(%JSONError{errors: response})
    end
  end

  def getCandidateProfileParams(post_params) do
    candidate_name = post_params["name"]
    candidate_experience = post_params["experience"]
    role_id = post_params["role_id"]
    additional_information = post_params["additional_information"]
    %{name: candidate_name, role_id: role_id, experience: candidate_experience, additional_information: additional_information}
  end

  def getChangesetErrorsInReadableFormat(changeset) do
    for n <- Keyword.keys(changeset.errors) do
      value = Keyword.get(changeset.errors,n)
      if is_tuple(value) do
        value = elem(value, 0)
      end
      %JSONErrorReason{field_name: n, reason: value}
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
