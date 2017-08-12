defmodule Release.Tasks do  
  def migrate do
    {:ok, _} = Application.ensure_all_started(:recruitx_backend)

    path = Application.app_dir(:recruitx_backend, "priv/repo/migrations")

    Ecto.Migrator.run(RecruitxBackend.Repo, path, :up, all: true)
  end
end
