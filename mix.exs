defmodule RecruitxBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :recruitx_backend,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps,
     preferred_cli_env: [espec: :test],
     test_coverage: [tool: ExCoveralls, test_task: "espec"]
   ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {RecruitxBackend, []},
     applications: [:phoenix, :cowboy, :logger,
                    :phoenix_ecto, :postgrex, :httpotion]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "spec/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.1.0"},
     {:phoenix_ecto, "~> 2.0"},
     {:postgrex, ">= 0.0.0"},
     {:cowboy, "~> 1.0"},
     {:exrm, "~> 0.19.9"},
     {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.2"},
     {:httpotion, "~> 2.1.0"},
     {:json,   "~> 0.3.0"},
     {:corsica, "~> 0.4"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:ectoo, "> 0.0.0", only: [:test]},
     {:espec_phoenix, "~> 0.1.8", only: :test, app: false},
     {:excoveralls, "~> 0.4.3", only: [:dev, :test]},
     {:ex_machina, "~> 0.6.1", only: :test, app: false},
     {:faker, "~> 0.5", only: :test, app: false}
   ]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"]]
  end
end
