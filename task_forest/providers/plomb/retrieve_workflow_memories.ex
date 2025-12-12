defmodule TaskForest.Providers.Plomb.RetrieveWorkflowMemories do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  alias TaskForest.Workflows
  alias TaskForest.Workflows.Memories
  alias TaskForest.Utils

  @impl true
  def run(
        %{task: task, inputs: %{"filters" => filters} = inputs, task_info: task_info} =
          task_context
      ) do
    with {:ok, filters_string} <- Jason.encode(filters),
         {:ok, filters_string_with_inputs} <- Workflows.fill_prompt_template(filters_string, inputs),
         sanitized_filters_as_string <- Utils.sanitize_malformed_json_string(filters_string_with_inputs),
         {:ok, filters_with_inputs} <- Jason.decode(sanitized_filters_as_string),
         memories <- Memories.retrieve_memories(task.workflow_id, filters_with_inputs) do
      if memories == [] do
        Logger.warning(
          "RetrieveWorkflowMemories.run - No memory found for workflow #{task.workflow_id}",
          task_info
        )
      end

      {:ok, %{"workflow_memories" => memories}}
    else
      {:error, error} ->
        Logger.error(
          "RetrieveWorkflowMemories.run - Error retrieving memories: #{inspect(error)}",
          task_info
        )

        {:error, "Error retrieving memories"}

      error ->
        Logger.error(
          "RetrieveWorkflowMemories.run - #{inspect(error)}",
          task_info
        )

        {:error, error}
    end
  end
end
