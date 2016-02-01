defmodule RecruitxBackend.Repo.Migrations.ChangeCandidateInterviewDateTimeToStartDate do
  use Ecto.Migration

  def change do
      rename table(:interviews), :candidate_interview_date_time, to: :start_time
  end
end
