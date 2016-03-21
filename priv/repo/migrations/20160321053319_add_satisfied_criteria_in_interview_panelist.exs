defmodule RecruitxBackend.Repo.Migrations.AddSatisfiedCriteriaInInterviewPanelist do
  use Ecto.Migration

  def change do
    alter table(:interview_panelists) do
      add :satisfied_criteria, :string
    end

    create unique_index(:interview_panelists, [:interview_id, :satisfied_criteria], name: :interview_panelist_criteria_index)
  end
end
