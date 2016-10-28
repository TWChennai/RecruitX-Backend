defmodule RecruitxBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :recruitx_backend,
     version: "1.0.0",
     elixir: "1.2.6",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps,
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
    # TODO: Need to verify that we actually need all the below (:connection, :json, :corsica)
     applications: [:timex, :timex_ecto, :phoenix, :cowboy, :logger, :connection,
                    :json, :phoenix_ecto, :postgrex, :httpotion, :scrivener, :gettext, :plug, :arc, :quantum, :swoosh]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "spec/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:arc, "~> 0.5.1"},
      {:cowboy, "~> 1.0.4"},
      {:credo, "~> 0.4.5", only: :test, app: false},
      {:cors_plug, "~> 1.1"},
      {:ecto, "~> 1.1.8"},
      {:ectoo, "~> 0.0.4", only: :test, app: false},
      {:espec_phoenix, "~> 0.2.0", only: :test, app: false},
      {:ex_aws, "~> 0.4.18"},
      {:ex_machina, "~> 0.6.1", only: :test, app: false},
      {:excoveralls, "~> 0.5.1", only: :test, app: false},
      {:exrm, "~> 0.19.9"},
      {:faker, "~> 0.6.0", only: :test, app: false},
      {:gettext, "~> 0.11.0"},
      {:httpoison, "~> 0.8.2"},
      {:httpotion, "~> 2.2.2"},
      {:json, "~> 0.3.3"},
      {:phoenix, "1.1.6"},
      {:phoenix_ecto, "2.0.2"},
      {:phoenix_live_reload, "~> 1.0.5", only: :dev},
      {:plug, "~> 1.0"},
      {:poison, "~> 2.1.0", override: true},
      {:postgrex, "~> 0.11.1"},
      {:quantum, ">= 1.7.0"},
      {:scrivener, "1.1.2"},    # TODO: Upgrading this to 1.2.1 causes breakage in specs - need to investigate
      {:swoosh, "~> 0.1.0"},
      {:timex, "~> 1.0.1"},
      {:timex_ecto, "~> 0.9.0"},
    ]
  end

  # Aliases are shortcut or tasks specific to the current project.
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
      commit: ["deps.get --only #{Mix.env}", "coveralls.html", "credo --strict"]
    ]
  end
end
