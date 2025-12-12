defmodule TaskForest.Models.GenericChatCompletion do
  @behaviour TaskForest.Models.ModelProvider

  require Logger

  alias TaskForest.Accounts
  alias TaskForest.Models.OpenAiFunctionsStreamingClient
  alias TaskForest.Utils

  # 20 minutes
  @chat_completion_timeout 60_000 * 20

  def call(
        model_id,
        model_params,
        input_params,
        provider_keys,
        task_info
      ) do
    error_prefix = "#{task_info.provider} - #{task_info.task_template_name} - #{task_info.name}"

    if model_params[:capability] != "chat_completion" do
      raise "Unsupported model capability - #{error_prefix}: #{model_params[:capability]}"
    end

    task =
      Elixir.Task.async(fn ->
        task_pid = self()

        model_params =
          model_params
          |> Enum.map(fn {k, v} -> {k, v} end)
          |> Keyword.merge(caller_pid: task_pid)

        case create_chat_completion(
               model_id,
               model_params,
               input_params,
               provider_keys,
               task_info
             ) do
          {:streaming, _streaming_client_pid} ->
            receive do
              {:streamed_response, %{content: content}} ->
                {:ok, content}

              {:error, error_message} ->
                Logger.error(
                  "Error streaming completion from #{error_prefix}: #{inspect(error_message)}",
                  task: task_info.task_template_name,
                  task_name: task_info.name,
                  provider: task_info.provider
                )

                {:error, "Error streaming completion from #{error_prefix}: #{inspect(error_message)}"}
            after
              @chat_completion_timeout ->
                Logger.error("Timeout streaming completion from #{error_prefix}",
                  task: task_info.task_template_name,
                  task_name: task_info.name,
                  provider: task_info.provider
                )

                {:error, "Timeout streaming completion from #{error_prefix}"}
            end

          {:error, error_message} ->
            Logger.error("Failed to call #{error_prefix} model: #{inspect(error_message)}",
              task: task_info.task_template_name,
              task_name: task_info.name,
              provider: task_info.provider
            )

            send(
              task_pid,
              {:error, "Failed to call #{error_prefix} model: #{inspect(error_message)}"}
            )
        end
      end)

    case Elixir.Task.await(task, @chat_completion_timeout) do
      {:ok, task_outputs} ->
        try do
          decoded_outputs =
            task_outputs
            |> cleanup_json()
            |> Jason.decode!()

          {:ok, decoded_outputs}
        rescue
          exception ->
            Logger.error("Error decoding #{error_prefix} response: #{inspect(exception)}",
              task: task_info.task_template_name,
              task_name: task_info.name,
              provider: task_info.provider
            )

            {:error, "Error decoding #{error_prefix} response: #{inspect(exception)}"}
        catch
          error ->
            Logger.error("Error decoding #{error_prefix} response: #{inspect(error)}",
              task: task_info.task_template_name,
              task_name: task_info.name,
              provider: task_info.provider
            )

            {:error, "Error decoding #{error_prefix} response: #{inspect(error)}"}
        end

      {:error, error_message} ->
        Logger.error("Error calling #{error_prefix} model: #{inspect(error_message)}",
          task: task_info.task_template_name,
          task_name: task_info.name,
          provider: task_info.provider
        )

        {:error, error_message}
    end
  end

  defp create_chat_completion(
         model_id,
         model_params,
         input_params,
         provider_keys,
         task_info
       ) do
    error_prefix = "#{task_info.provider} - #{task_info.task_template_name} - #{task_info.name}"

    caller_pid = model_params[:caller_pid]

    streaming_client_initial_state = %{content: "", caller_pid: caller_pid}

    with {:ok, provider_keys} <- maybe_decrypt_provider_keys(provider_keys),
         messages <- build_messages(input_params),
         {:ok, streaming_client_pid} <-
           OpenAiFunctionsStreamingClient.start_link(streaming_client_initial_state),
         opts <-
           Keyword.merge(model_params,
             openai_api_key: get_in(provider_keys, ["api_key"]),
             stream: true,
             stream_to: streaming_client_pid
           ),
         {:ok, hackney_stream_ref} <-
           ExOpenAI.Chat.create_chat_completion(messages, model_id, opts) do
      OpenAiFunctionsStreamingClient.set_stream_ref(streaming_client_pid, hackney_stream_ref)

      Logger.info("Started streaming completion from #{error_prefix}",
        task: task_info.task_template_name,
        task_name: task_info.name,
        provider: task_info.provider
      )

      {:streaming, caller_pid}
    else
      {:error, error_message} ->
        Logger.error(
          "Error starting streaming completion from #{error_prefix}: #{inspect(error_message)}",
          task: task_info.task_template_name,
          task_name: task_info.name,
          provider: task_info.provider
        )

        {:error, "Error starting streaming completion from #{error_prefix}: #{inspect(error_message)}"}
    end
  end

  defp build_messages(%{"loaded_prompt" => loaded_prompt, "image_url" => image_url} = _input_params) do
    [
      %ExOpenAI.Components.ChatCompletionRequestSystemMessage{
        role: :system,
        content: loaded_prompt
      },
      %ExOpenAI.Components.ChatCompletionRequestSystemMessage{
        role: :user,
        content: [
          %ExOpenAI.Components.ChatCompletionRequestMessageContentPartImage{
            type: :image_url,
            image_url: %{
              url: image_url
            }
          }
        ]
      }
    ]
  end

  defp build_messages(%{"loaded_prompt" => loaded_prompt, "images" => images} = _input_params) do
    image_messages =
      Enum.map(images, fn image_url ->
        %ExOpenAI.Components.ChatCompletionRequestSystemMessage{
          role: :user,
          content: [
            %ExOpenAI.Components.ChatCompletionRequestMessageContentPartImage{
              type: :image_url,
              image_url: %{
                url: image_url
              }
            }
          ]
        }
      end)

    [
      %ExOpenAI.Components.ChatCompletionRequestSystemMessage{
        role: :system,
        content: loaded_prompt
      }
    ] ++ image_messages
  end

  defp build_messages(%{"loaded_prompt" => loaded_prompt} = _input_params) do
    [
      %ExOpenAI.Components.ChatCompletionRequestSystemMessage{
        role: :user,
        content: loaded_prompt
      }
    ]
  end

  def cleanup_json(json_string) do
    json_string
    |> String.trim_leading()
    |> String.replace("<|eom", "")
    |> Utils.maybe_extract_json_from_markdown()
    |> Utils.maybe_extract_json_from_reasoning()
  end

  defp maybe_decrypt_provider_keys(provider_keys) do
    case provider_keys do
      %{keys: %{"api_key" => _api_key} = keys} ->
        {:ok, keys}

      %{keys: encrypted_keys} when is_binary(encrypted_keys) ->
        Accounts.decrypt_provider_keys(provider_keys)
    end
  end
end
