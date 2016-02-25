defmodule RecruitxBackend.Repo.Migrations.AddOneMorePipelineStatus do
  use Ecto.Migration

  alias RecruitxBackend.Repo
  alias RecruitxBackend.PipelineStatus

  def change do
    #TODO it should be moved to create_pipeline_status migration

    Repo.insert!(%RecruitxBackend.PipelineStatus{name: PipelineStatus.pass})
  end
end
