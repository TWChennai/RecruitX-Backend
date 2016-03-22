defmodule RecruitxBackend.Repo.Migrations.AddSatisfiedCriteriaInInterviewPanelist do
  use Ecto.Migration

  def change do
    alter table(:interview_panelists) do
      add :satisfied_criteria, :string
    end
  end
end
