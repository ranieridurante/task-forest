defmodule TaskForest.Accounts.Workers.Oauth2TokenRefreshWorker do
  use Oban.Pro.Worker,
    queue: :default,
    max_attempts: 3,
    priority: 0

  require Logger

  alias TaskForest.Accounts
  alias TaskForest.Providers

  @impl true
  def process(%{attempt: 3, args: %{"app_id" => app_id, "provider_keys_id" => provider_keys_id}}) do
    Logger.error("Max refresh token attempts reached for app_id=#{app_id} provider_keys_id=#{provider_keys_id}")

    # TODO: Send email: Accounts.send_token_refresh_failed_email(app_id)

    {:discard, "Max attempts reached"}
  end

  def process(%{
        args: %{"app_id" => app_id, "provider_keys_id" => provider_keys_id}
      }) do
    Logger.info("Oauth2TokenRefreshWorker started for app_id=#{app_id}")

    case Accounts.get_provider_keys(provider_keys_id) do
      {:ok, provider_keys} ->
        Providers.refresh_oauth2_token(app_id, provider_keys)

      {:error, _} ->
        Logger.info("Skipping refreshing token, provider keys not found for provider_keys_id=#{provider_keys_id}")

        :ok
    end
  end
end
