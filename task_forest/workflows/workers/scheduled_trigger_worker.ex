defmodule TaskForest.Workflows.Workers.ScheduledTriggerWorker do
  use Oban.Pro.Worker, queue: :default, max_attempts: 3

  require Logger

  alias TaskForest.Workflows

  @impl true
  def backoff(%{meta: %{"cron_expr" => cron_expression}} = _job) do
    if is_cron_with_rapid_interval?(cron_expression) do
      # 15 seconds
      15
    else
      # 15 minutes
      60 * 15
    end
  end

  @impl true
  def process(%Oban.Job{
        args: %{"name" => name, "workflow_id" => workflow_id, "inputs" => inputs}
      }) do
    Logger.info("ScheduledTriggerWorker started for workflow_id=#{workflow_id} with name=#{name}")

    case Workflows.execute_workflow(workflow_id, inputs) do
      {:ok, execution_id} ->
        Logger.info("Workflow #{workflow_id} executed successfully with execution_id=#{execution_id}")

        :ok

      {:error, :not_enough_credits} ->
        Logger.error("Not enough credits to execute workflow #{workflow_id}")
        # TODO: Send email to company admin about the lack of credits

        {:error, :not_enough_credits}

      {:error, reason} ->
        Logger.error("Error executing workflow #{workflow_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp is_cron_with_rapid_interval?(cron_expression) do
    three_hours_or_less_regex =
      ~r/^(\*|\*\/[1-9]|[0-5]?[0-9](,[0-5]?[0-9])*)\s+(\*|\*\/[1-2]|0,1,2|[0-2]?[0-9](,[0-2]?[0-9])*)\s+.*$/

    Regex.match?(
      three_hours_or_less_regex,
      cron_expression
    )
  end
end
