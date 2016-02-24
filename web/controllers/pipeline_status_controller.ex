defmodule RecruitxBackend.PipelineStatusController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.PipelineStatus

  def index(conn, _params) do
    pipeline_statuses = PipelineStatus |> Repo.all
    conn |> render("index.json", pipeline_statuses: pipeline_statuses)
  end
end
