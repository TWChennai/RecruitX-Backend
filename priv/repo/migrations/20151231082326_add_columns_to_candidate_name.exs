defmodule RecruitxBackend.Repo.Migrations.AddColumnsToCandidateName do
  use Ecto.Migration

  def change do
    alter table(:candidates) do
      add :role_id, references(:roles), null: false
      add :experience, :decimal, null: false, precision: 4, scale: 2
      add :addtional_information, :string
    end
  end
end
