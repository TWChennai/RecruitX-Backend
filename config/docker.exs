use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
#
config :recruitx_backend, RecruitxBackend.Endpoint,
	http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}], # This is critical for ensuring web-sockets properly authorize.
  server: true,
  root: ".",
  version: Application.spec(:recruitx_backend, :vsn)

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :recruitx_backend, RecruitxBackend.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "recruitx",
  password: "recruitx",
  database: "recruitx_backend_prod",
  hostname: "db",
  pool_size: 10

config :recruitx_backend, RecruitxBackend.Mailer,
    adapter: Swoosh.Adapters.Local
