defmodule RecruitxBackend.Repo.Migrations.AddCaseInsensitiveUniqueIndex do
  use Ecto.Migration

  def change do
      drop unique_index(:skills, [:name])
      execute "CREATE UNIQUE INDEX skills_name_index ON skills (UPPER(name));"
  end
end
