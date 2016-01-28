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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

# This line was automatically added by ansible-elixir-stack setup script
if System.get_env("SERVER") do
  config :phoenix, :serve_endpoints, true
end
