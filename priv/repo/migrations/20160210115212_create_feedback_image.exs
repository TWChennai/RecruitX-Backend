defmodule RecruitxBackend.Repo.Migrations.CreateFeedbackImage do
  use Ecto.Migration

  def change do
    create table(:feedback_images) do
      add :file_name, :string, null: false
      add :interview_id, references(:interviews), null: false

      timestamps
    end
    create unique_index(:feedback_images, [:file_name, :interview_id], name: :feedback_file_name_interview_id_unique_index)
    execute "CREATE UNIQUE INDEX file_name_unique_index ON feedback_images (UPPER(file_name));"
  end
end
