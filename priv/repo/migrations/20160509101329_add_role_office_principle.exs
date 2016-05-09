defmodule RecruitxBackend.Repo.Migrations.AddRoleOfficePrinciple do
  use Ecto.Migration

  def change do
      execute "INSERT INTO roles (name, inserted_at, updated_at) VALUES ('Off Prin', now(), now());"
  end
end
