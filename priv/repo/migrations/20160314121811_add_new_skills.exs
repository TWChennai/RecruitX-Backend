defmodule RecruitxBackend.Repo.Migrations.AddNewSkills do
  use Ecto.Migration

  def change do
    Enum.each(["Selenium",
              "QTP",
              "CI",
              "Performance"], fn skill_value ->
      execute "INSERT INTO skills (name, inserted_at, updated_at) VALUES ('#{skill_value}', now(), now());"
    end)
  end
end
