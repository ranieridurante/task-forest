defmodule TaskForest.Providers.Plomb.StoreWorkflowMemory do
  @behaviour TaskForest.Tasks.ElixirTask

  alias TaskForest.Workflows.Memories

  @impl true
  def run(
        %{task: task, inputs: %{"data_slots_to_store" => keys} = inputs, task_info: task_info} =
          _task_context
      ) do
    data =
      keys
      |> String.split(",")
      |> then(&Map.take(inputs, &1))

    error_prefix =
      "StoreWorkflowMemory.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    memory = %{
      workflow_id: task.workflow_id,
      data: data
    }

    case Memories.store_memory(memory) do
      {:ok, memory} ->
        {:ok, %{"memory" => memory}}

      {:error, error_message} ->
        {:error, "#{error_prefix} - Failed to store memory: #{inspect(error_message)}"}
    end
  end
end
