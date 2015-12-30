defmodule RecruitxBackend.Repo.Migrations.CreateInterview do
  use Ecto.Migration

  def change do
    create table(:interviews) do
      add :name, :string, null: false
      add :priority, :integer

      timestamps
    end
    create unique_index(:interviews, [:name])
  end
end
