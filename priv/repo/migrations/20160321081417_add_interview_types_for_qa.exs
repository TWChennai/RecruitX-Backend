defmodule RecruitxBackend.Repo.Migrations.AddInterviewTypesForQa do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Repo

  def change do
    Enum.each([InterviewType.telephonic], fn interview_type_value ->
      Repo.insert!(%InterviewType{name: interview_type_value, priority: 1})
    end)
  end
end
