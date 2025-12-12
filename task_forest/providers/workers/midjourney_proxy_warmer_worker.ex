defmodule TaskForest.Providers.Workers.MidjourneyProxyWarmerWorker do
  use Oban.Pro.Worker, recorded: true

  require TaskForest.Providers.DynamicHttpClient

  alias TaskForest.Providers.DynamicHttpClient

  @impl true
  def process(_job) do
    midjourney_api_key = System.get_env("MIDJOURNEY_API_KEY")

    request_info = %{
      name: "warm-midjourney-proxy",
      method: :get,
      uri: "/mj/account/list",
      params: %{},
      host: "https://midjourney.plomb.ai",
      headers: [
        {"mj-api-secret", midjourney_api_key},
        {"Content-Type", "application/json"}
      ]
    }

    DynamicHttpClient.perform_request(
      request_info.name,
      request_info.method,
      request_info.uri,
      request_info.params,
      "",
      request_info.host,
      request_info.headers
    )
  end
end
