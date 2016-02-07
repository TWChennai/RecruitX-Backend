defmodule RecruitxBackend.Repo.Migrations.CreateInterviewType do
  use Ecto.Migration

  def change do
    create table(:interview_types) do
      add :name, :string, null: false
      add :priority, :integer

      timestamps
    end

    execute "CREATE UNIQUE INDEX interview_types_name_index ON interview_types (UPPER(name));"
  end
end
