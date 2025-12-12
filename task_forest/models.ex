defmodule TaskForest.Models do
  require Logger

  def call_model(
        provider_slug,
        %{
          model_id: model_id,
          model_params: model_params,
          inputs: input_params,
          provider_keys: provider_keys
        } = _context,
        task_info
      ) do
    module_name =
      case provider_slug do
        "open-ai" -> "OpenAi"
        "plomb" -> "PlombAi"
        _ -> "GenericChatCompletion"
      end

    module = Module.concat(["TaskForest.Models", module_name])

    error_message_prefix =
      "#{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    if Code.ensure_loaded?(module) and function_exported?(module, :call, 5) do
      try do
        apply(module, :call, [model_id, model_params, input_params, provider_keys, task_info])
      rescue
        exception ->
          Logger.error("Error calling model: #{inspect(exception)}",
            task: task_info.task_template_name,
            task_name: task_info.name,
            provider: task_info.provider
          )

          {:error, "#{error_message_prefix} Error calling model: #{inspect(exception.message)}"}
      catch
        error ->
          Logger.error("Error calling model: #{inspect(error)}",
            task: task_info.task_template_name,
            task_name: task_info.name,
            provider: task_info.provider
          )

          {:error, "#{error_message_prefix} Error calling model: #{inspect(error)}"}
      end
    else
      Logger.error("Provider not implemented: #{provider_slug}",
        task: task_info.task_template_name,
        task_name: task_info.name,
        provider: task_info.provider
      )

      {:error, "Provider not implemented: #{provider_slug}"}
    end
  end
end
