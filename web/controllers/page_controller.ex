defmodule RecruitxBackend.PageController do
  use RecruitxBackend.Web, :controller

alias RecruitxBackend.Candidate

  def index(conn, _params) do
    candidates =  candidates = Candidate.get_candidates_in_fifo_order
              |> Repo.all

    render(conn, "index.html", candidates: candidates)
  end
end
