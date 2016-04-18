defmodule RecruitxBackend.Repo.Migrations.ModifyPriorityOfTpRoundToZero do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType

  def change do
    execute "UPDATE interview_types set priority=0 where name='"<>InterviewType.telephonic<>"';"
  end
end
