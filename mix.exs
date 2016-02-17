defmodule RecruitxBackend.Mixfile do
  use Mix.Project

  def project do
    {result, _exit_code} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    git_sha = String.strip(result)

    [app: :recruitx_backend,
     version: "0.0.8-#{git_sha}",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps,
     preferred_cli_env: [espec: :test, spec: :test, coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, commit: :test, credo: :test],
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
                    :json, :corsica, :phoenix_ecto, :postgrex, :httpotion]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "spec/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.1.4"},
     {:phoenix_ecto, "~> 2.0.1"},
     {:postgrex, "~> 0.11.1"},
     {:cowboy, "~> 1.0.4"},
     {:exrm, "~> 0.19.9"},
     {:httpotion, "~> 2.2.0"},
     {:json, "~> 0.3.3"},
     {:corsica, "~> 0.4.0"},
     {:timex, "~> 1.0.1"},
     {:timex_ecto, "~> 0.8.0"},
     {:phoenix_live_reload, "~> 1.0.3", only: :dev},
     {:credo, "~> 0.3.2", only: :test, app: false},
     {:ectoo, "~> 0.0.4", only: :test, app: false},
     {:espec_phoenix, "~> 0.2.0", only: :test, app: false},
     {:excoveralls, "~> 0.4.6", only: :test, app: false},
     {:ex_machina, "~> 0.6.1", only: :test, app: false},
     {:faker, "~> 0.6.0", only: :test, app: false},
     {:gettext, "~> 0.9"}
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
      commit: ["deps.get --only #{Mix.env}", "espec --cover", "credo -i todo,duplicatedcode --strict"]
    ]
  end
end
