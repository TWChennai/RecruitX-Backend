defmodule RecruitxBackend.CandidateController do
    use RecruitxBackend.Web, :controller

    alias RecruitxBackend.Candidate

    def index(conn, _params) do
        json conn, Candidate.all
    end

    def create(conn, candidate_params) do
        if(Candidate.insert(candidate_params)) do
            send_resp(conn, 200, "")
        else
            send_resp(conn, 400, "")
        end
    end
end
