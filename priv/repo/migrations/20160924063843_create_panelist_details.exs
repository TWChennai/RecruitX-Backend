defmodule RecruitxBackend.Repo.Migrations.CreatePanelistDetails do
  use Ecto.Migration

  def change do
    create table(:panelist_details, primary_key: false) do
      add :panelist_login_name, :string, null: false, primary_key: true
      add :employee_id, :decimal, null: false
      add :role_id, references(:roles)

      timestamps()
    end

    create index(:panelist_details, ["UPPER(panelist_login_name)", "employee_id"], unique: true, name: :panelist_details_index)
  end
end
