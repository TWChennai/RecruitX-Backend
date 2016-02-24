defmodule RecruitxBackend.InterviewTypeController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewType

  def index(conn, _params) do
    interview_types = InterviewType |> InterviewType.default_order |> Repo.all
    conn |> render("index.json", interview_types: interview_types)
  end
end
