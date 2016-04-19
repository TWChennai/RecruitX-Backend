defmodule RecruitxBackend.MailHelper do
  import Swoosh.Email
  alias RecruitxBackend.Mailer

  def deliver(email) do
    email
    |> override_default
    |> construct_swoosh_mail
    |> Mailer.deliver
  end

  def override_default(email) do
    Map.merge(default_mail, email)
  end

  def default_mail do
    %{
      subject: "[RecruitX] Test Email",
      from: System.get_env("DEFAULT_FROM_EMAIL_ADDRESS"),
      to: System.get_env("DEFAULT_TO_EMAIL_ADDRESSES") |> String.split,
      html_body: "<h1>Test Email</h1><p>RecruitX test email content</p>",
      text_body: "RecruitX test email content"
    }
  end

  defp construct_swoosh_mail(mail) do
    %Swoosh.Email{}
    |> from(mail.from)
    |> subject(mail.subject)
    |> html_body(mail.html_body)
    |> text_body(mail.text_body)
    |> to(mail.to)
  end
end
