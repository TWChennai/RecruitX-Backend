# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :recruitx_backend, RecruitxBackend.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "7XiwvpwOfCMr4RfxZjKwUkdIplKq9K01Pve9W4eooXM3v3/60CF4quYDpbiBM2l4",
  render_errors: [accepts: ~w(json)],
  pubsub: [name: RecruitxBackend.PubSub, adapter: Phoenix.PubSub.PG2],
  http: [compress: true]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :arc,
  bucket: System.get_env("AWS_BUCKET")

config :ex_aws,
  access_key_id: [System.get_env("AWS_ACCESS_KEY_ID"), :instance_role],
  secret_access_key: [System.get_env("AWS_SECRET_ACCESS_KEY"), :instance_role]

config :quantum, cron: [
  remove_unused_slots: [
    schedule: "@daily",
    task: "RecruitxBackend.Slot.delete_unused_slots"
  ],
  weekly_signup_reminder: [
    schedule: "30 02 * * 2",
    task: "RecruitxBackend.WeeklySignupReminder.execute"
  ],
  weekly_status_update: [
    schedule: "30 0 * * 6",
    task: "RecruitxBackend.StatusUpdate.execute_weekly",
  ],
  monthly_status_update: [
    schedule: "30 0 1 * *",
    task: "RecruitxBackend.StatusUpdate.execute_monthly",
  ],
  jan_status_update: [
    schedule: "30 0 1 1 *",
    task: "RecruitxBackend.StatusUpdate.execute_quarterly",
  ],
  april_status_update: [
    schedule: "30 0 1 4 *",
    task: "RecruitxBackend.StatusUpdate.execute_quarterly",
  ],
  july_status_update: [
    schedule: "30 0 1 7 *",
    task: "RecruitxBackend.StatusUpdate.execute_quarterly",
  ],
  oct_status_update: [
    schedule: "30 0 1 10 *",
    task: "RecruitxBackend.StatusUpdate.execute_quarterly",
  ],
  team_details_update: [
    schedule: "0 * * * *",
    task: "RecruitxBackend.TeamDetailsUpdate.execute",
  ]
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
