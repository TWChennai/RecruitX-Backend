defmodule RecruitxBackend.Repo.Migrations.AddRoleQa do
  use Ecto.Migration

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role

  def change do
      Repo.insert!(%Role{name: Role.qa})
  end
end
