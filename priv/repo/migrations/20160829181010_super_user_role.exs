defmodule RecruitxBackend.Repo.Migrations.SuperUserRole do
  use Ecto.Migration

  alias RecruitxBackend.Role

  @ops Role.ops
  @office_principal Role.office_principal

  def change do
    execute "UPDATE roles SET name = '#{@ops}' where name='#{@office_principal}';"
  end
end
