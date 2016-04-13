defmodule RecruitxBackend.SosEmail do
  import Ecto.Query, only: [preload: 2, order_by: 2]

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias MailmanExtensions.Mailer
  alias MailmanExtensions.Templates

  def execute do
    interviews_with_insufficient_panelists = Interview.interviews_with_insufficient_panelists
      |> preload([:interview_type, candidate: [:role,:skills]])
      |> order_by(asc: :start_time)
      |> Repo.all
      |> construct_view_data

      if interviews_with_insufficient_panelists != [] do
        Mailer.deliver %{
           subject: "[RecruitX] SOS Signup Reminder",
           to: System.get_env("WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
           html: interviews_with_insufficient_panelists |> Templates.sos_email
       }
    end
  end

  defp construct_view_data(interviews) do
    Enum.map(interviews, fn(interview) ->
      %{
        candidate: %{
          name: interview.candidate.first_name <> " " <> interview.candidate.last_name,
          role: interview.candidate.role.name,
          experience: interview.candidate |> Candidate.get_rounded_experience,
          skills: interview.candidate |> Candidate.get_formatted_skills
        }
      }
      |> Map.merge(Interview.format interview)
    end)
  end

end
