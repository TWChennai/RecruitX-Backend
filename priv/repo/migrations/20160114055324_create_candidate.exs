defmodule RecruitxBackend.Repo.Migrations.CreateCandidate do
  use Ecto.Migration

  alias RecruitxBackend.Repo
  alias RecruitxBackend.PipelineStatus

  import Ecto.Query, only: [from: 2, where: 2]

  def change do
    in_progess_id = PipelineStatus.retrieve_by_name("In Progress").id
    create table(:candidates) do
      add :name, :string
      add :experience, :decimal, null: false, precision: 4, scale: 2
      add :other_skills, :string
      add :role_id, references(:roles)
      add :pipeline_status_id, references(:pipeline_statuses), null: false, default: in_progess_id

      timestamps
    end

    create index(:candidates, [:role_id])
  end
end
