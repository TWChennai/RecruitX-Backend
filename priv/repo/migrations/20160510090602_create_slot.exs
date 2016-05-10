defmodule RecruitxBackend.Repo.Migrations.CreateSlot do
  use Ecto.Migration

  def change do
    create table(:slots) do
      add :role_id, references(:roles)
      add :interview_type_id, references(:interview_types), null: false
      add :start_time, :datetime, null: false
      add :end_time, :datetime, null: false

      timestamps
    end

  end
end
