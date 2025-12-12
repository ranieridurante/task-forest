defmodule TaskForest.Providers.Plomb.GetUrlContent do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  @impl true
  def run(%{inputs: %{"plomb_get_url" => url}, task_info: task_info}) do
    error_prefix =
      "GetUrlContent.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    middleware = [
      {Tesla.Middleware.Logger, debug: true},
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Curl, logger_level: :debug}
    ]

    client = Tesla.client(middleware, {Tesla.Adapter.Mint, []})

    case Tesla.get(client, url) do
      {:ok, response} ->
        {:ok, %{"plomb_url_content" => "#{inspect(response.body)}"}}

      {:error, reason} ->
        Logger.error("#{error_prefix} - Failed to get URL content: #{inspect(reason)}")
        {:error, "#{error_prefix} - Failed to get URL content: #{inspect(reason)}"}
    end
  end
end
