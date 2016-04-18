defmodule RecruitxBackend.Repo.Migrations.AddTpForDev do
  use Ecto.Migration

  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo
  import Ecto.Query, only: [from: 2, where: 2]

  def change do
    dev_role = Role.retrieve_by_name(Role.dev)
    interview_type_id = (from it in InterviewType, where: it.name==^InterviewType.telephonic, select: it.id) |> Repo.one
    execute "INSERT INTO role_interview_types (role_id, interview_type_id, inserted_at, updated_at) VALUES (#{dev_role.id}, #{interview_type_id}, now(), now());"
  end
end
