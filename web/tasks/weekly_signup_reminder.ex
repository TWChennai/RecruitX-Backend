defmodule RecruitxBackend.WeeklySignupReminder do
  import Ecto.Query
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate

  def get_candidates_and_interviews(sub_query) do
    candidates = Candidate
    |> preload([:role, [:candidate_skills, candidate_skills: [:skill]], interviews: ^sub_query])
    |> Repo.all
    Enum.filter(candidates, &(!Enum.empty?(&1.interviews)))
  end

  def construct_view_data(candidates_and_interviews) do
    Enum.map(candidates_and_interviews, fn(candidate) -> %{
      name: candidate.first_name <> " " <> candidate.last_name,
      experience: candidate.experience,
      role: candidate.role.name,
      interviews: Enum.map(candidate.interviews, fn(interview) -> %{
        name: interview.interview_type.name,
        date: Timex.DateFormat.format!(interview.start_time, "%b-%d", :strftime)
      }
      end),
      skills: (Enum.reduce(candidate.candidate_skills, "", fn(candidate_skill, accumulator) ->
        skill = candidate_skill.skill.name
        if skill == "Other", do: skill = candidate.other_skills
        accumulator <> ", " <> skill
      end))
      |> String.lstrip(?,)
      |> String.lstrip
    }
    end)
  end

end
