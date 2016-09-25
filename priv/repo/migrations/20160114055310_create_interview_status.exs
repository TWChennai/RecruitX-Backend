defmodule RecruitxBackend.Repo.Migrations.CreateInterviewStatus do
  use Ecto.Migration

  alias RecruitxBackend.InterviewStatus

  def change do
    create table(:interview_status) do
      add :name, :string, null: false

      timestamps
    end

    create index(:interview_status, ["UPPER(name)"], unique: true, name: :interview_status_name_index)

    flush

    Enum.each([InterviewStatus.pass,
              InterviewStatus.pursue,
              InterviewStatus.strong_pursue], fn status_value ->
      execute "INSERT INTO interview_status (name, inserted_at, updated_at) VALUES ('#{status_value}', now(), now());"
    end)
  end
end
