defmodule RecruitxBackend.PageController do
  use RecruitxBackend.Web, :controller

alias RecruitxBackend.Interview
alias RecruitxBackend.Panel

  def index(conn, _params) do
    interviews = Interview.get_interviews_with_associated_data
                              |> preload([:interview_type, candidate: :role])
                              |> Repo.all

    render(conn, "index.html", interviews: interviews)
  end
end
