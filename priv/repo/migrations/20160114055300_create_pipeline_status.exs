defmodule RecruitxBackend.Repo.Migrations.CreatePipelineStatus do
  use Ecto.Migration

  def change do
    create table(:pipeline_statuses) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX pipeline_statuses_name_index ON pipeline_statuses (UPPER(name));"

    flush

    Enum.each(["In Progress",
              "Closed"], fn pipeline_status_value ->
      execute "INSERT INTO pipeline_statuses (name, inserted_at, updated_at) VALUES ('#{pipeline_status_value}', now(), now());"
    end)
  end
end
