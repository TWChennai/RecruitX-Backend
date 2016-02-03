defmodule RecruitxBackend.Repo.Migrations.RemoveUniqueIndexOnPanelistLoginName do
  use Ecto.Migration

  def change do
    execute "DROP INDEX panelist_login_name_index;"
  end
end
