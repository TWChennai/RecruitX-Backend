defmodule RecruitxBackend.Repo.Migrations.CreateInterview do
  use Ecto.Migration

  def change do
    create table(:interviews) do
      add :name, :string, null: false
      add :priority, :integer

      timestamps
    end

    execute "CREATE UNIQUE INDEX interviews_name_index ON interviews (UPPER(name));"
  end
end
