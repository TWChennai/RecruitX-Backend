defmodule RecruitxBackend.Repo.Migrations.AddCaseInsensitiveUniqueConstraintForRoleAndInterviewName do
  use Ecto.Migration

  def change do
     drop unique_index(:roles, [:name])
     execute "CREATE UNIQUE INDEX roles_name_index ON roles (UPPER(name));"

     drop unique_index(:interviews, [:name])
     execute "CREATE UNIQUE INDEX interviews_name_index ON interviews (UPPER(name));"
  end
end
