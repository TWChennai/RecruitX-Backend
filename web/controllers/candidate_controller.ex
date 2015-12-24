defmodule RecruitxBackend.CandidateController do
    use RecruitxBackend.Web, :controller

    alias RecruitxBackend.Candidate
    alias RecruitxBackend.Repo

    def index(conn, _params) do
        json conn, Repo.all(Candidate)
    end

    def create(conn, candidate_params) do
      changeset = Candidate.changeset(%Candidate{}, candidate_params)
      if(changeset.valid?) do
        Repo.insert(changeset)
        send_resp(conn, 200, "")
      else
        send_resp(conn, 400, "")
      end
    end
end
