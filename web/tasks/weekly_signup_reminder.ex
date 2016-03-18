defmodule RecruitxBackend.WeeklySignupReminder do
  import Ecto.Query
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate

  def get_candidates_and_interviews(sub_query) do
    candidates = Candidate
    |> preload([:role, :skills, interviews: ^sub_query])
    |> Repo.all

    Enum.filter(candidates, &(!Enum.empty?(&1.interviews)))
  end

  def construct_view_data(candidates_and_interviews) do
    Enum.map(candidates_and_interviews, fn(candidate) -> %{
      name: candidate.first_name <> " " <> candidate.last_name,
      experience: candidate.experience,
      role: candidate.role.name,
      interviews: Candidate.get_formatted_interviews(candidate),
      skills: Candidate.get_formatted_skills(candidate)
    }
    end)
  end
end
