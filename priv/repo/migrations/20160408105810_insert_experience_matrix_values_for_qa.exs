defmodule RecruitxBackend.Repo.Migrations.InsertExperienceMatrixValuesForQa do
  use Ecto.Migration

  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewType

  def change do
    qa_role_id = Role.retrieve_by_name(Role.qa).id
    Enum.each([
    %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => 4, "candidate_experience_upper_bound" => 4, "interview_type" => InterviewType.telephonic},
    %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => -1, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => -1, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 4, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.telephonic},
    %{"panelist_experience_lower_bound" => 4, "candidate_experience_lower_bound" => 4, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 4, "candidate_experience_lower_bound" => -1, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 6, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_1},
    %{"panelist_experience_lower_bound" => 6, "candidate_experience_lower_bound" => 4, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_2},
    %{"panelist_experience_lower_bound" => 8, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99, "interview_type" => InterviewType.technical_2}],
    fn %{"panelist_experience_lower_bound" => panelist_experience_lower_bound,
      "candidate_experience_lower_bound" => candidate_experience_lower_bound,
      "candidate_experience_upper_bound" => candidate_experience_upper_bound,
      "interview_type" => interview_type} ->
        interview_type = interview_type |> InterviewType.retrieve_by_name
        execute "INSERT INTO experience_matrices (panelist_experience_lower_bound, candidate_experience_lower_bound, candidate_experience_upper_bound, interview_type_id, role_id, inserted_at, updated_at) VALUES (#{Decimal.new(panelist_experience_lower_bound)}, #{Decimal.new(candidate_experience_lower_bound)}, #{Decimal.new(candidate_experience_upper_bound)}, #{interview_type.id}, #{qa_role_id}, now(), now());"
    end)
  end
end
