defmodule RecruitxBackend.Repo.Migrations.AddExperienceMatrixForDevTpi do
  use Ecto.Migration
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.Role
  def change do
    telephonic_interview_type_id = InterviewType.retrieve_by_name(InterviewType.telephonic).id
    dev_role_id = Role.retrieve_by_name(Role.dev).id


    Enum.each([
        %{"panelist_experience_lower_bound" => 1, "candidate_experience_lower_bound" => 2, "candidate_experience_upper_bound" => 2},
        %{"panelist_experience_lower_bound" => 3, "candidate_experience_lower_bound" => 5, "candidate_experience_upper_bound" => 5},
        %{"panelist_experience_lower_bound" => 5, "candidate_experience_lower_bound" => 8, "candidate_experience_upper_bound" => 8},
        %{"panelist_experience_lower_bound" => 8, "candidate_experience_lower_bound" => 12, "candidate_experience_upper_bound" => 12},
        %{"panelist_experience_lower_bound" => 10, "candidate_experience_lower_bound" => 99, "candidate_experience_upper_bound" => 99}],
        fn %{"panelist_experience_lower_bound" => panelist_experience_lower_bound,
          "candidate_experience_lower_bound" => candidate_experience_lower_bound,
          "candidate_experience_upper_bound" => candidate_experience_upper_bound} ->
            execute "INSERT INTO experience_matrices (panelist_experience_lower_bound, candidate_experience_lower_bound, candidate_experience_upper_bound, interview_type_id, role_id, inserted_at, updated_at) VALUES (#{Decimal.new(panelist_experience_lower_bound)}, #{Decimal.new(candidate_experience_lower_bound)}, #{Decimal.new(candidate_experience_upper_bound)}, #{telephonic_interview_type_id}, #{dev_role_id}, now(), now());"
        end)
  end
end
