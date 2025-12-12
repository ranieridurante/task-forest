defmodule TaskForest.Release do
  require Logger

  @app :task_forest

  def migrate do
    if check_migrations_enabled() do
      load_app()

      Logger.info("Migrating repo")

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TaskForest.Repo, &Ecto.Migrator.run(&1, :up, all: true))
    else
      Logger.info("Migrations are disabled")
    end
  end

  def rollback(repo, version) do
    load_app()

    Logger.info("Rollbacking repo #{repo} to version #{version}")

    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp load_app do
    Application.load(@app)
  end

  defp check_migrations_enabled do
    Application.get_env(@app, TaskForest.Repo)[:migrations_enabled]
  end
end
