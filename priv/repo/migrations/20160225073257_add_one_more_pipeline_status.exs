defmodule RecruitxBackend.Repo.Migrations.AddOneMorePipelineStatus do
  use Ecto.Migration

  alias RecruitxBackend.Repo

  def change do
    #TODO it should be moved to create_pipeline_status migration
    flush

    # TODO: Magic string!
    Repo.insert!(%RecruitxBackend.PipelineStatus{name: "Pass"})
  end
end
