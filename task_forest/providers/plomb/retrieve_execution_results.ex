defmodule TaskForest.Providers.Plomb.RetrieveExecutionResults do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  alias TaskForest.Workflows

  @impl true
  def run(
        %{inputs: %{"plomb_execution_id" => "SKIP"} = _inputs, task_info: task_info} =
          _task_context
      ) do
    Logger.debug(
      "RetrieveExecutionResults.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name} - Skipping execution"
    )

    {:ok, %{"plomb_workflow_results" => "SKIP"}}
  end

  def run(
        %{inputs: %{"plomb_execution_id" => task_execution_id} = _inputs, task_info: task_info} =
          _task_context
      ) do
    error_prefix =
      "RetrieveExecutionResult.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    case Workflows.retrieve_execution_results(task_execution_id) do
      {:ok, %{execution: execution}} ->
        {:ok, %{"plomb_workflow_results" => execution.outputs}}

      {:error, error_message} ->
        Logger.error("#{error_prefix} - Failed to retrieve execution results: #{inspect(error_message)}")

        {:error, "#{error_prefix} - Failed to retrieve execution results: #{inspect(error_message)}"}
    end
  end
end
