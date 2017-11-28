defmodule Swoosh.Templates do
  require EEx
  EEx.function_from_file(:def, :weekly_signup_reminder, "web/templates/mail/weekly_signup_reminder.html.eex", [:candidates_with_insufficient_signups, :candidates_with_sufficient_signups])
  EEx.function_from_file(:def, :status_update, "web/templates/mail/status_update.html.eex", [:start_date, :to_date, :summary, :exclude_details])
  EEx.function_from_file(:def, :team_status_update, "web/templates/mail/team_status_update.html.eex", [:start_date, :to_date, :summary])
  EEx.function_from_file(:def, :status_update_default, "web/templates/mail/status_update_default.html.eex", [:start_date, :to_date])
  EEx.function_from_file(:def, :consolidated_feedback, "web/templates/mail/consolidated_feedback.html.eex", [:candidate])
  EEx.function_from_file(:def, :sos_email, "web/templates/mail/sos_email.html.eex", [:interviews_with_insufficient_panelists])
  EEx.function_from_file(:def, :panelist_removal_notification, "web/templates/mail/panelist_removal_notification.html.eex", [:panliest_removed, :candidate_first_name, :candidate_last_name, :interview_name, :interview_date])
  EEx.function_from_file(:def, :interview_cancellation_notification, "web/templates/mail/interview_cancellation_notification.html.eex", [:candidate_first_name, :candidate_last_name, :interview_name, :interview_date])
  EEx.function_from_file(:def, :slot_cancellation_notification, "web/templates/mail/slot_cancellation_notification.html.eex", [:interview_type_name, :slot_date])
end
