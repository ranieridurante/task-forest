defmodule TaskForest.Providers.Plomb.TextSplitter do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  @impl true
  def run(%{
        inputs: %{"plomb_text" => text, "plomb_separator" => separator} = _inputs,
        task_info: task_info
      }) do
    text_parts = String.split(text, separator)

    {:ok, %{"plomb_text_parts" => text_parts}}
  rescue
    _ ->
      error_prefix =
        "TextSplitter.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

      error_message =
        "#{error_prefix} - Missing required input: plomb_text or plomb_separator"

      Logger.error(error_message)
      {:error, error_message}
  end
end
