defmodule RecruitxBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :recruitx_backend,
     version: "1.0.0",
     elixir: "1.3.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     preferred_cli_env: [
                          espec: :test,
                          spec: :test,
                          coveralls: :test,
                          "coveralls.detail": :test,
                          "coveralls.html": :test,
                          "coveralls.post": :test,
                          commit: :test,
                          credo: :test
                        ],
     test_coverage: [tool: ExCoveralls, test_task: "espec"]
   ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {RecruitxBackend, []},
     # TODO: Need to verify that we actually need all the below (:connection, :corsica)
     applications: [:timex, :timex_ecto, :phoenix, :cowboy, :logger, :connection, :httpotion, :gen_smtp,
                    :phoenix_ecto, :postgrex, :scrivener, :gettext, :plug, :arc, :quantum, :swoosh]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "spec/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:arc, "~> 0.6.0"},
      {:cors_plug, "~> 1.1"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.5.3", only: :test, app: false},
      {:espec_phoenix, "~> 0.6", only: :test, app: false, override: true},
      {:espec_phoenix_helpers, "~> 0.3.3", only: :test},
      {:ex_aws, "~> 1.0"},
      {:ex_machina, "~> 1.0.2", only: :test, app: false},
      {:excoveralls, "~> 0.6", only: :test, app: false},
      {:faker, "~> 0.7.0", only: :test, app: false}, # TODO: Replace with: {:faker_elixir_octopus, "~> 0.12.0", only: [:dev, :test]},
      {:gettext, "~> 0.12"},
      {:gen_smtp, "~> 0.11.0"},
      {:httpotion, "~> 3.0"},
      {:phoenix, "~> 1.2", override: true},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_swoosh, "~> 0.1.3"},
      {:poison, "~> 2.2"},
      {:postgrex, "~> 0.12"},
      {:quantum, "~> 1.8"},
      {:scrivener_ecto, "~> 1.1"},
      {:timex_ecto, "~> 3.1.0"},
      {:sweet_xml, "~> 0.5"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "spec": "espec",
      "ecto.seed": "run priv/repo/seeds.exs",
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      # TODO: Turning off 'credo' till the elixir upgrade is completed
      # commit: ["deps.get --only #{Mix.env}", "coveralls.html", "credo --strict"]
      commit: ["deps.get --only #{Mix.env}", "coveralls.html"]
    ]
  end
end
