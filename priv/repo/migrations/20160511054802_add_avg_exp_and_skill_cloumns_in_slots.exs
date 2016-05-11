defmodule RecruitxBackend.Repo.Migrations.AddAvgExpAndSkillCloumnsInSlots do
  use Ecto.Migration

  def change do
    alter table(:slots) do
      add :average_experience, :decimal, precision: 4, scale: 2
      add :skills, :string
    end
  end
end
