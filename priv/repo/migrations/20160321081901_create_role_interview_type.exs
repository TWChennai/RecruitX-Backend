defmodule RecruitxBackend.Repo.Migrations.CreateRoleInterviewType do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.RoleInterviewType
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role

  def change do
    create table(:role_interview_types) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :interview_type_id, references(:interview_types, on_delete: :delete_all), null: false

      timestamps
    end

    create unique_index(:role_interview_types, [:role_id, :interview_type_id], name: :role_interview_type_id_index)

    flush

    dev_role = Role.retrieve_by_name(Role.dev)
    Enum.each([InterviewType.coding,
      InterviewType.technical_1,
      InterviewType.technical_2,
      InterviewType.leadership,
      InterviewType.p3
    ], fn interview_type_value ->
      Repo.insert!(%RoleInterviewType{role_id: dev_role.id, interview_type_id: InterviewType.retrieve_by_name(interview_type_value).id})
    end)

    qa_role = Role.retrieve_by_name(Role.qa)
    Enum.each([InterviewType.telephonic,
      InterviewType.technical_1,
      InterviewType.technical_2,
      InterviewType.leadership,
      InterviewType.p3
    ], fn interview_type_value ->
      Repo.insert!(%RoleInterviewType{role_id: qa_role.id, interview_type_id: InterviewType.retrieve_by_name(interview_type_value).id})
    end)

  end
end
