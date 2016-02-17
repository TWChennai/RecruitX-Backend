defmodule RecruitxBackend.Repo.Migrations.CreateInterviewStatus do
  use Ecto.Migration

  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.Repo

  def change do
    create table(:interview_status) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX interview_status_name_index ON interview_status (UPPER(name));"

    flush

    Enum.map(["Pass",
              "Pursue",
              "Strong Pursue"], fn status_value ->
      Repo.insert!(%InterviewStatus{name: status_value})
    end)
  end
end
