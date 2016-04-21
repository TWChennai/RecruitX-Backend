defmodule RecruitxBackend.Repo.Migrations.AddRoleBaPmAndTheirInterviews do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Role
  alias RecruitxBackend.Skill
  alias RecruitxBackend.Repo

  import Ecto.Query, only: [from: 2, where: 2]

  def change do
    Enum.each(["BA",
              "PM"], fn role_value ->
      execute "INSERT INTO roles (name, inserted_at, updated_at) VALUES ('#{role_value}', now(), now());"
    end)

    flush

    ba_role_id = Role.retrieve_by_name(Role.ba).id
    pm_role_id = Role.retrieve_by_name(Role.pm).id
    other_skill_id = Skill.other_skill_id
    telephonic_interview_id = InterviewType.retrieve_by_name(InterviewType.telephonic).id

    Enum.each([ba_role_id, pm_role_id], fn role_id ->
      execute "INSERT INTO role_interview_types (role_id, interview_type_id, optional, inserted_at, updated_at) VALUES (#{role_id}, #{telephonic_interview_id}, true, now(), now());"
      Enum.each([InterviewType.technical_1,
        InterviewType.technical_2,
        InterviewType.leadership,
        InterviewType.p3
      ], fn interview_type_value ->
        interview_type_id = (from it in InterviewType, where: it.name==^interview_type_value, select: it.id) |> Repo.one
        execute "INSERT INTO role_interview_types (role_id, interview_type_id, inserted_at, updated_at) VALUES (#{role_id}, #{interview_type_id}, now(), now());"
      end)
      execute "INSERT INTO role_skills (role_id, skill_id, inserted_at, updated_at) VALUES (#{role_id}, #{other_skill_id}, now(), now())"
    end)
  end
end
