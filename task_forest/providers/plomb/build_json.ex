defmodule TaskForest.Providers.Plomb.BuildJson do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  alias TaskForest.Utils
  alias TaskForest.Workflows

  def run(%{inputs: %{"plomb_json_template" => json_template} = inputs, task_info: task_info}) do
    with {:ok, filled_template} <- Workflows.fill_prompt_template(json_template, inputs),
         sanitized_json_string <- Utils.sanitize_malformed_json_string(filled_template),
         {:ok, json} <- Jason.decode(sanitized_json_string) do
      {:ok, %{"plomb_json" => json}}
    else
      {:error, error} ->
        error_message =
          "BuildJson.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name} - Invalid JSON template #{inspect(error)}"

        Logger.error(error_message)
        {:error, error_message}

      error ->
        Logger.error(
          "BuildJson.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name} - Invalid JSON template"
        )

        {:error, "BuildJson.run Invalid JSON template: #{inspect(error)}"}
    end
  end
end
