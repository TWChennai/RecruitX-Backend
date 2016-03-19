defmodule MailmanExtensions.Templates do
  require EEx
  EEx.function_from_file(:def, :weekly_signup_reminder, "web/templates/mail/weekly_signup_reminder.html.eex", [:candidates_with_insufficient_signups, :candidates_with_sufficient_signups])
end
