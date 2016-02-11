defmodule RecruitxBackend.Repo.Migrations.AddingUniqueIndexesInFeedbackImages do
  use Ecto.Migration

  def change do
    create unique_index(:feedback_images, [:file_name, :interview_id], name: :feedback_file_name_interview_id_unique_index)
    execute "CREATE UNIQUE INDEX file_name_unique_index ON feedback_images (UPPER(file_name));"
  end
end
