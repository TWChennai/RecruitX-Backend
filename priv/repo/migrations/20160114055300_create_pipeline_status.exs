defmodule RecruitxBackend.Repo.Migrations.CreatePipelineStatus do
  use Ecto.Migration

  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Repo

  def change do
    create table(:pipeline_statuses) do
      add :name, :string, null: false

      timestamps
    end
    execute "CREATE UNIQUE INDEX pipeline_statuses_name_index ON pipeline_statuses (UPPER(name));"
    flush
    Enum.map(["In Progress",
              "Closed"], fn pipeline_status_value ->
      Repo.insert!(%PipelineStatus{name: pipeline_status_value})
    end)
  end
end
