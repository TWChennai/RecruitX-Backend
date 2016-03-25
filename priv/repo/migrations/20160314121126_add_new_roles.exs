defmodule RecruitxBackend.Repo.Migrations.AddRoleQa do
  use Ecto.Migration

  def change do
    Enum.each(["QA",
              "Other"], fn role_value ->
      execute "INSERT INTO roles (name, inserted_at, updated_at) VALUES ('#{role_value}', now(), now());"
    end)
  end
end
