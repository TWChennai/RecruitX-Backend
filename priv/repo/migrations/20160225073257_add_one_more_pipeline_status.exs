defmodule RecruitxBackend.Repo.Migrations.AddOneMorePipelineStatus do
  use Ecto.Migration

  def change do
    #TODO it should be moved to create_pipeline_status migration
    execute "INSERT INTO pipeline_statuses (name, inserted_at, updated_at) VALUES ('Pass', now(), now());"
  end
end
