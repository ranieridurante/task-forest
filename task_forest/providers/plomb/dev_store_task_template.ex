defmodule TaskForest.Providers.Plomb.DevStoreTaskTemplate do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  alias TaskForest.Tasks
  alias TaskForest.Tasks.TaskTemplate

  @impl true
  def run(
        %{
          inputs: %{"plomb_raw_task_template" => raw_task_template} = _inputs,
          task_info: task_info
        } =
          _task_context
      ) do
    error_prefix =
      "DevStoreTaskTemplate.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    case Tasks.store_task_template(%TaskTemplate{}, raw_task_template) do
      {:ok, _} ->
        {:ok, %{}}

      {:error, error_message} ->
        Logger.error("#{error_prefix} #{inspect(error_message)}")

        {:error, error_message}
    end
  end
end
