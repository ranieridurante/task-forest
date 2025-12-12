defmodule TaskForest.Providers.Plomb.ExecuteWorkflow do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  alias TaskForest.Workflows

  @impl true
  # TODO: remove after implementing IF nodes
  def run(
        %{inputs: %{"plomb_workflow_id" => "SKIP"} = _inputs, task_info: task_info} =
          _task_context
      ) do
    Logger.debug(
      "ExecuteWorkflow.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name} - Skipping execution"
    )

    {:ok, %{"plomb_execution_id" => "SKIP"}}
  end

  # TODO: add auth to check if the user has access to the workflow
  def run(
        %{
          inputs:
            %{
              "plomb_workflow_id" => task_workflow_id,
              "plomb_workflow_inputs" => task_workflow_inputs
            } = _inputs,
          task_info: task_info
        } = _task_context
      ) do
    error_prefix =
      "ExecuteWorkflow.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    case Workflows.execute_workflow(task_workflow_id, task_workflow_inputs) do
      {:ok, execution_id} ->
        {:ok, %{"plomb_execution_id" => execution_id}}

      {:error, error_message} ->
        Logger.error("#{error_prefix} - Failed to execute workflow: #{inspect(error_message)}")

        {:error, "#{error_prefix} - Failed to execute workflow: #{inspect(error_message)}"}
    end
  end
end
