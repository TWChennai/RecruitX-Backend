defmodule RecruitxBackend.Repo.Migrations.AddUniqueConstrainToSkillName do
  use Ecto.Migration

  def change do
    create unique_index(:skills, [:name])
  end
end
