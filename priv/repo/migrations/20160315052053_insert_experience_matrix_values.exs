defmodule RecruitxBackend.Repo.Migrations.InsertExperienceMatrixValues do
  use Ecto.Migration

  alias RecruitxBackend.InterviewType

  import Ecto.Query, only: [from: 2, where: 2]
  alias RecruitxBackend.Repo

  def change do
    Enum.each([
    %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => 2, "candidate_experience_upper_bound" => 2, "interview_type" => InterviewType.coding},
    %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => 2, "candidate_experience_upper_bound" => 5, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => -1, "candidate_experience_upper_bound" => 5, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 3, "candidate_experience_lower_bound" => 5, "candidate_experience_upper_bound" => 5, "interview_type" => InterviewType.coding},
    %{"panelist_experience_lower_bound" => 3, "candidate_experience_lower_bound" => 5, "candidate_experience_upper_bound" => 8, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 3, "candidate_experience_lower_bound" => -1, "candidate_experience_upper_bound" => 8, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 4, "candidate_experience_lower_bound" => 2, "candidate_experience_upper_bound" => 8, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 5, "candidate_experience_lower_bound" => 8, "candidate_experience_upper_bound" => 8, "interview_type" => InterviewType.coding},
    %{"panelist_experience_lower_bound" => 5, "candidate_experience_lower_bound" => 8, "candidate_experience_upper_bound" => 12, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 5, "candidate_experience_lower_bound" => 5, "candidate_experience_upper_bound" => 12, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 8, "candidate_experience_lower_bound" => 12, "candidate_experience_upper_bound" => 12, "interview_type" => InterviewType.coding},
    %{"panelist_experience_lower_bound" => 8, "candidate_experience_lower_bound" => 12, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 8, "candidate_experience_lower_bound" => 8, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 10, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.coding},
    %{"panelist_experience_lower_bound" => 10, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 10, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_2}],
    fn %{"panelist_experience_lower_bound" => panelist_experience_lower_bound,
      "candidate_experience_lower_bound" => candidate_experience_lower_bound,
      "candidate_experience_upper_bound" => candidate_experience_upper_bound,
      "interview_type" => interview_type} ->
        interview_type_id = (from it in InterviewType, where: it.name==^interview_type, select: it.id) |> Repo.one
        execute "INSERT INTO experience_matrices (panelist_experience_lower_bound, candidate_experience_lower_bound, candidate_experience_upper_bound, interview_type_id, inserted_at, updated_at) VALUES (#{Decimal.new(panelist_experience_lower_bound)}, #{Decimal.new(candidate_experience_lower_bound)}, #{Decimal.new(candidate_experience_upper_bound)}, #{interview_type_id}, now(), now());"
    end)
  end
end
