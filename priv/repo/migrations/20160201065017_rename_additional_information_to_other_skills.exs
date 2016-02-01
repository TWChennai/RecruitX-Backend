defmodule RecruitxBackend.Repo.Migrations.RenameAdditionalInformationToOtherSkills do
  use Ecto.Migration

  def change do
    rename table(:candidates), :additional_information, to: :other_skills
  end
end
