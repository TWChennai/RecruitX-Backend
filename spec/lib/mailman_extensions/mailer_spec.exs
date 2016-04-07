defmodule  MailmanExtensions.MailerSpec do
  use ESpec.Phoenix, model:  MailmanExtensions.Mailer

  alias MailmanExtensions.Mailer
  alias RecruitxBackend.Interview
  alias Mailman.Email
  alias Mailman.Context

  import Ecto.Query

  describe "override default email" do
    let :default_email do
      default_email = %Email {
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
    end

    it "should return the default email struct on passing an empty struct" do
      actual_email = Mailer.override_default(%{})

      expect(actual_email) |> to(be(default_email))
    end

    it "should override the appropriate fields in the default email on passing a non-empty struct" do
      email = %{
        subject: "Subject",
        to: ["someone@example.com", "abcd@example.com"]
      }
      expected_email = %Email{ default_email | subject: email.subject, to: email.to }
      actual_email = Mailer.override_default(email)

      expect(actual_email) |> to(be(expected_email))
    end
  end

  describe "deliver email" do
    it "should call the deliver method" do
      allow Mailman |> to(accept(:deliver, fn(_, _) -> "" end))
      Mailer.deliver(%{})

      expect Mailman |> to(accepted :deliver, [Mailer.override_default(%{}), %Context{}])
    end
  end
end
