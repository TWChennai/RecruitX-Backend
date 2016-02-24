defmodule RecruitxBackend.InterviewStatusController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewStatus

  def index(conn, _params) do
    interview_status = InterviewStatus |> Repo.all
    conn |> render("index.json", interview_status: interview_status)
  end
end
