defmodule TaskForest.Workflows.Workers.InitWorkflowWorker do
  use Oban.Pro.Workers.Workflow, recorded: [limit: 128_000]

  require Logger

  @impl true
  def process(%{
        meta: %{"name" => "workflow_inputs"},
        args: %{
          "workflow_inputs" => workflow_inputs,
          "workflow_id" => workflow_id,
          "inputs_hash" => inputs_hash
        }
      }) do
    Logger.debug("Initializing workflow_id=#{workflow_id} for inputs_hash=#{inputs_hash}")

    outputs =
      Map.merge(
        workflow_inputs,
        %{
          "inputs_hash" => inputs_hash,
          "workflow_id" => workflow_id
        }
      )

    {:ok, outputs}
  end
end
