defmodule MailmanExtensions.Mailer do
  def deliver(email) do
    email = override_default(email)
    Mailman.deliver(email, %Mailman.Context{})
  end

  def override_default(email) do
    default_email = %Mailman.Email {
      subject: "[RecruitX] Test Email",
      from: System.get_env("DEFAULT_FROM_EMAIL_ADDRESS"),
      reply_to: "",
      to: System.get_env("DEFAULT_TO_EMAIL_ADDRESSES") |> String.split,
      cc: [],
      bcc: [],
      attachments: [],
      data: %{},
      html: "<h1>Test Email</h1><p>RecruitX test email content</p>",
      text: "RecruitX test email content",
      delivery: nil
    }
    Map.merge(default_email, email)
  end
end
