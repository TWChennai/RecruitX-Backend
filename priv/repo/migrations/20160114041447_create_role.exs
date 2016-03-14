defmodule RecruitxBackend.Repo.Migrations.CreateRole do
  use Ecto.Migration

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role

  def change do
    create table(:roles) do
      add :name, :string, null: false

      timestamps
    end

    execute "CREATE UNIQUE INDEX roles_name_index ON roles (UPPER(name));"

    flush

    Repo.insert!(%Role{name: Role.dev})
  end
end
