defmodule RecruitxBackend.WeeklySignupReminder do
  import Ecto.Query

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Role
  alias RecruitxBackend.Interview
  alias Swoosh.Templates
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.Repo

  def execute do
    interview_ids = Interview.interviews_with_insufficient_panelists
    |> select([i], i.id)
    |> Repo.all

    {insufficient_signups_query, sufficient_signups_query} = get_interview_sub_queries(interview_ids)
    roles = Role.get_all_roles
    Enum.each(roles, fn(%{name: role_name, id: role_id}) ->
      candidates_with_insufficient_signups = insufficient_signups_query
        |> get_candidates_and_interviews(role_id)
        |> construct_view_data

      candidates_with_sufficient_signups = sufficient_signups_query
        |> get_candidates_and_interviews(role_id)
        |> construct_view_data

      if candidates_with_insufficient_signups != [] or candidates_with_sufficient_signups != [] do

        email_content = Templates.weekly_signup_reminder(candidates_with_insufficient_signups, candidates_with_sufficient_signups)

        MailHelper.deliver(%{
         subject: "[RecruitX] " <> role_name <> " Signup Reminder",
         to: System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
         html_body: email_content
       })
      end
    end)
  end

  def get_interview_sub_queries(interview_ids) do
    {
      Interview
        |> preload(:interview_type)
        |> where([i], i.id in ^interview_ids)
        |> order_by(asc: :start_time)
        |> Interview.tuesday_to_friday_of_the_current_week,
      Interview
        |> preload(:interview_type)
        |> where([i], not(i.id in ^interview_ids))
        |> order_by(asc: :start_time)
        |> Interview.tuesday_to_friday_of_the_current_week
    }
  end

  def get_candidates_and_interviews(sub_query, role_id) do
    candidates = Candidate
    |> preload([:role, :skills, interviews: ^sub_query])
    |> where([c], c.role_id == ^role_id)
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
