defmodule RecruitxBackend.Repo.Migrations.CreateInterviewType do
  use Ecto.Migration

  def change do
    create table(:interview_types) do
      add :name, :string, null: false
      add :priority, :integer

      timestamps()
    end

    create index(:interview_types, ["UPPER(name)"], unique: true, name: :interview_types_name_index)

    flush

    Enum.each(%{"Coding" => 1,
               "Tech-1" => 2,
               "Tech-2" => 3,
               "Ldrshp" => 4,
               "P3" => 4}, fn {name_value, priority_value} ->
      execute "INSERT INTO interview_types (name, priority, inserted_at, updated_at) VALUES ('#{name_value}', #{priority_value}, now(), now());"
    end)
  end
end
