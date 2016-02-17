defmodule RecruitxBackend.PipelineStatusView do
  use RecruitxBackend.Web, :view

  def render("index.json", %{pipeline_statuses: pipeline_statuses}) do
    render_many(pipeline_statuses, RecruitxBackend.PipelineStatusView, "pipeline_status.json")
  end

  # def render("show.json", %{pipeline_status: pipeline_status}) do
  #   %{data: render_one(pipeline_status, RecruitxBackend.PipelineStatusView, "pipeline_status.json")}
  # end

  def render("pipeline_status.json", %{pipeline_status: pipeline_status}) do
    %{id: pipeline_status.id,
      name: pipeline_status.name}
  end
end
