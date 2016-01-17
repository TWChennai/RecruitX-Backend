defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill

  # TODO: Need to fix the spec to pass context "invalid params" and check scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, _params) do
    json conn, Repo.all(Candidate)
    # candidates = Repo.all(Candidate)
    # render(conn, "index.json", candidates: candidates)
  end

  def create(conn, %{"candidate" => post_params}) do
    skill_ids = readSkillIdsOrRaiseError(post_params)
    {status, result_of_db_transaction} = Repo.transaction fn ->
      {candidate_insertion_status, result_of_db_transaction} = insertCandidate(post_params)
      if candidate_insertion_status == :ok do
          insertCandidateSkills(result_of_db_transaction, skill_ids)
      else
          Repo.rollback(result_of_db_transaction)
      end
    end
    sendResponseBasedOnResult(conn, status, result_of_db_transaction)
  end

  def insertCandidate(post_params) do
    candidate_changeset = Candidate.changeset(%Candidate{}, getCandidateProfileParams(post_params))
    if candidate_changeset.valid? do
      {status, candidate} = Repo.insert(candidate_changeset)
    else
      errors = for n <- Keyword.keys(candidate_changeset.errors), do: "#{n} #{Keyword.get(candidate_changeset.errors,n)}"
      {:error, errors}
    end
  end

  def readSkillIdsOrRaiseError(post_params) do
    skill_ids=post_params["skill_ids"]
      unless skill_ids do
        raise Phoenix.MissingParamError, key: "skill_ids"
      end
    skill_ids
  end

  def insertCandidateSkills(candidate, skill_ids) do
    candidate_skill_changesets = for n <- skill_ids, do: CandidateSkill.changeset(%CandidateSkill{}, %{candidate_id: candidate.id, skill_id: n})
      result = Enum.all?(candidate_skill_changesets, fn(changeset) ->
        changeset.valid?
      end)
      if result do
        Enum.each(candidate_skill_changesets, fn(x) -> Repo.insert(x) end)
      else
        #TODO: send changeset errors
        Repo.rollback("Invalid Data")
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
          |> json(response)
    end
  end

  def getCandidateProfileParams(post_params) do
    candidate_name = post_params["name"]
    candidate_experience = post_params["experience"]
    role_id = post_params["role_id"]
    additional_skills = post_params["additional_information"]
    %{name: candidate_name, role_id: role_id, experience: candidate_experience, additional_information: additional_skills}
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
