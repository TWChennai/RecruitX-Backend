defmodule RecruitxBackend.CandidateController do
    use RecruitxBackend.Web, :controller

    alias RecruitxBackend.Candidate
    alias RecruitxBackend.Repo

    def index(conn, _params) do
        json conn, Repo.all(Candidate)
    end

    def create(conn, candidate_params) do
      # HACKTAG: Want to checkin this change, but still haven't wired up the other parameters and the role association from the UI
      changeset = Candidate.changeset(%Candidate{}, Dict.merge(candidate_params, %{"role_id" => 1, "experience" => Decimal.new(3)}))
      if changeset.valid? do
        Repo.insert(changeset)
        send_resp(conn, 200, "")
      else
        send_resp(conn, 400, "")
      end
    end
end
