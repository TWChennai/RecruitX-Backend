defmodule  RecruitxBackend.MailHelperSpec do
  use ESpec.Phoenix, model: RecruitxBackend.MailHelper

  alias RecruitxBackend.MailHelper


  describe "override default email" do
    let :default_email do
      %{
        subject: "[RecruitX] Test Email",
        from: System.get_env("DEFAULT_FROM_EMAIL_ADDRESS"),
        to: System.get_env("DEFAULT_TO_EMAIL_ADDRESSES") |> String.split,
        html_body: "<h1>Test Email</h1><p>RecruitX test email content</p>",
        text_body: "RecruitX test email content"
      }
    end

    it "should return the default email struct" do
      actual_email = MailHelper.default_mail()

      expect(actual_email) |> ESpec.To.to(be(default_email))
    end

    it "should override the appropriate fields in the default email on passing a non-empty struct" do
     email = %{
       subject: "Subject",
       to: ["someone@example.com", "abcd@example.com"]
     }
     expected_email = %{ default_email | subject: email.subject, to: email.to }
     actual_email = MailHelper.override_default(email)

     expect(actual_email) |> to(be(expected_email))
   end
 end
end
