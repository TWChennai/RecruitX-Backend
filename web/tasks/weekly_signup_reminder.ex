defmodule RecruitxBackend.WeeklySignupReminder do
  import Ecto.Query
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias MailmanExtensions.Templates
  alias MailmanExtensions.Mailer

  def execute do
    interview_ids = Interview.interviews_with_insufficient_panelists
    |> select([i], i.id)
    |> Repo.all

    {insufficient_signups_query, sufficient_signups_query} = get_interview_sub_queries(interview_ids)

    candidates_with_insufficient_signups = insufficient_signups_query
      |> get_candidates_and_interviews
      |> construct_view_data

    candidates_with_sufficient_signups = sufficient_signups_query
      |> get_candidates_and_interviews
      |> construct_view_data

    if candidates_with_insufficient_signups != [] or candidates_with_sufficient_signups != [] do
      email_content = Templates.weekly_signup_reminder(candidates_with_insufficient_signups, candidates_with_sufficient_signups)
      Mailer.deliver(%{
        subject: "[RecruitX]Reminder: Upcoming Interviews",
        to: [System.get_env("TW_CHENNAI_EMAIL_ADDRESS")],
        html: email_content
      })
    end
  end

  def get_interview_sub_queries(interview_ids) do
    {
      Interview
        |> preload(:interview_type)
        |> where([i], i.id in ^interview_ids)
        |> Interview.now_or_in_next_seven_days,
      Interview
        |> preload(:interview_type)
        |> where([i], not(i.id in ^interview_ids))
        |> Interview.now_or_in_next_seven_days
    }
  end

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
