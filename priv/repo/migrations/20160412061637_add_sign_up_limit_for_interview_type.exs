defmodule RecruitxBackend.Repo.Migrations.AddSignUpLimitForInterviewType do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType

  def change do
    alter table(:interview_types) do
      add :max_sign_up_limit, :integer , null: false, default: 2
    end

    flush

    execute "DROP TRIGGER check_signup_validity on interview_panelists;"

    execute "UPDATE interview_types SET max_sign_up_limit = 1 WHERE name IN ('" <> InterviewType.coding <> "', '" <> InterviewType.telephonic <> "');"
  end
end
