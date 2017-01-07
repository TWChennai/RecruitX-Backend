defmodule RecruitxBackend.Repo.Migrations.AddPipelineClosureTime do
  use Ecto.Migration

  alias RecruitxBackend.PipelineStatus

  def change do
    alter table(:candidates) do
      add :pipeline_closure_time, :datetime
    end

    closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

    flush

    execute "UPDATE candidates SET pipeline_closure_time = candidates.updated_at WHERE pipeline_status_id = #{closed_pipeline_status_id}"
  end
end
