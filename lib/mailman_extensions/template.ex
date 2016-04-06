defmodule MailmanExtensions.Templates do
  require EEx
  EEx.function_from_file(:def, :weekly_signup_reminder, "web/templates/mail/weekly_signup_reminder.html.eex", [:candidates_with_insufficient_signups, :candidates_with_sufficient_signups])
  EEx.function_from_file(:def, :weekly_status_update, "web/templates/mail/weekly_status_update.html.eex", [:start_date, :to_date, :candidates])
  EEx.function_from_file(:def, :weekly_status_update_default, "web/templates/mail/weekly_status_update_default.html.eex", [:start_date, :to_date])
  EEx.function_from_file(:def, :consolidated_feedback, "web/templates/mail/consolidated_feedback.html.eex", [:candidate])
end
