defmodule RecruitxBackend.Repo.Migrations.CreateSignupCops do
  use Ecto.Migration

  def change do
    create table(:signup_cops) do
      add :name, :string

      timestamps()
    end

  end
end
