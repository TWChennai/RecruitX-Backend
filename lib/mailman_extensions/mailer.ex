defmodule MailmanExtensions.Mailer do
  alias Mailman.Attachment

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

  def get_feedback_images_as_attachment_for([head | tail], result \\ []) do
    get_feedback_images_as_attachment_for(tail, result ++ get_feedback_images_as_attachment(head.feedback_images, head.interview_type.name))
  end

  def get_feedback_images_as_attachment_for([], result) do
    result
  end

  def get_feedback_images_as_attachment(feedback_images, interview_name) do
    Enum.reduce(feedback_images, [], fn(feedback_image, accumulator) ->
      file_name = interview_name <> "_" <> feedback_image.file_name
      accumulator ++ [Attachment.attach!("https://" <> System.get_env("AWS_DOWNLOAD_URL") <> feedback_image.file_name, file_name)]
    end)
  end
end
