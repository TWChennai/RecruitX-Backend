 defmodule RecruitxBackend.Repo.Migrations.AddOptionalFieldForRoleInterviewType do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo

  import Ecto.Query, only: [from: 2, where: 2]

  def change do
    alter table(:role_interview_types) do
      add :optional, :boolean, null: false, default: false
    end

    flush

    telephonic_round_id = (from it in InterviewType, where: it.name==^InterviewType.telephonic, select: it.id) |> Repo.one
    execute "UPDATE role_interview_types SET optional=true WHERE interview_type_id=" <> (telephonic_round_id |> Integer.to_string) <> " ;"
  end
end
