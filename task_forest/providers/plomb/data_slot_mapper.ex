defmodule TaskForest.Providers.Plomb.DataSlotMapper do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  @impl true
  def run(%{
        inputs: %{"plomb_current_name" => current_name, "plomb_new_name" => new_name} = inputs,
        task_info: task_info
      }) do
    value = inputs[current_name]

    {:ok, %{new_name => value}}
  rescue
    _ ->
      error_prefix =
        "DataSlotMapper.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

      error_message =
        "#{error_prefix} - Missing required input: plomb_current_name or plomb_new_name"

      Logger.error(error_message)
      {:error, error_message}
  end
end
