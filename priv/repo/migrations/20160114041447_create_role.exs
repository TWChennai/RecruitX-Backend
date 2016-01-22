defmodule RecruitxBackend.Repo.Migrations.CreateRole do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX roles_name_index ON roles (UPPER(name));"
  end
end