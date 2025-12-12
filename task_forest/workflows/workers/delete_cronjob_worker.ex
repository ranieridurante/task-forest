defmodule TaskForest.Workflows.Workers.DeleteCronjobWorker do
  use Oban.Pro.Worker, queue: :default, max_attempts: 3

  require Logger

  alias Oban.Pro.Plugins.DynamicCron

  @impl true
  def perform(%Oban.Job{args: %{"cronjob_name" => cronjob_name}}) do
    case DynamicCron.delete(cronjob_name) do
      {:ok, _} ->
        Logger.info("Successfully deleted  cronjob with name=#{cronjob_name}")

        :ok

      {:error, reason} ->
        Logger.error("Failed to delete cronjob with name=#{cronjob_name}, reason: #{inspect(reason)}")

        {:error, "Failed to delete cronjob"}
    end
  end
end
