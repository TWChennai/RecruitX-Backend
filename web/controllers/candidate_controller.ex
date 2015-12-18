defmodule RecruitxBackend.CandidateController do
    use RecruitxBackend.Web, :controller

    def index(conn, _params) do
        json conn, %{:name => "hello"}
    end

end