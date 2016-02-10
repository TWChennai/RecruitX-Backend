defmodule RecruitxBackend.Repo.Migrations.CreateFeedbackImage do
  use Ecto.Migration

  def change do
    create table(:feedback_images) do
      add :file_name, :string, null: false
      add :interview_id, references(:interviews), null: false

      timestamps
    end

  end
end
