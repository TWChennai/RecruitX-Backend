defmodule RecruitxBackend.WeeklySignupReminder do
  import Ecto.Query

  alias MailmanExtensions.Mailer
  alias MailmanExtensions.Templates
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo

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
        subject: "[RecruitX] Signup Reminder",
        to: System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
        html: email_content
      })
    end
  end

  def get_interview_sub_queries(interview_ids) do
    {
      Interview
        |> preload(:interview_type)
        |> where([i], i.id in ^interview_ids)
        |> order_by(asc: :start_time)
        |> Interview.working_days_in_next_week,
      Interview
        |> preload(:interview_type)
        |> where([i], not(i.id in ^interview_ids))
        |> order_by(asc: :start_time)
        |> Interview.working_days_in_next_week
    }
  end

  def get_candidates_and_interviews(sub_query) do
    candidates = Candidate
    |> preload([:role, :skills, interviews: ^sub_query])
    |> Repo.all

    # TODO: Is there a better way to invoke the 'having' clause via Ecto?
    Enum.filter(candidates, &(!Enum.empty?(&1.interviews)))
  end

  def construct_view_data(candidates_and_interviews) do
    Enum.map(candidates_and_interviews, fn(candidate) -> %{
      name: candidate.first_name <> " " <> candidate.last_name,
      experience: Candidate.get_rounded_experience(candidate),
      role: candidate.role.name,
      interviews: Candidate.get_formatted_interviews(candidate),
      skills: Candidate.get_formatted_skills(candidate)
    }
    end)
  end
end
