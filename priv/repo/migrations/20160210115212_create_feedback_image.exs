defmodule RecruitxBackend.Repo.Migrations.CreateFeedbackImage do
  use Ecto.Migration

  def change do
    create table(:feedback_images) do
      add :file_name, :string, null: false
      add :interview_id, references(:interviews, on_delete: :delete_all), null: false

      timestamps
    end

    create index(:feedback_images, [:file_name, :interview_id], unique: true, name: :feedback_file_name_interview_id_unique_index)
    create index(:feedback_images, ["UPPER(file_name)"], unique: true, name: :file_name_unique_index)
  end
end
