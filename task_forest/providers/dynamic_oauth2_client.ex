defmodule TaskForest.Providers.DynamicOAuth2Client do
  require Logger

  def authorize_url(%{"client_config" => raw_client_config, "extra_params" => extra_params} = _app_config) do
    authorize_url =
      raw_client_config
      |> init()
      |> OAuth2.Client.authorize_url!(extra_params)

    {:ok, authorize_url}
  end

  def refresh_token(
        %{
          "client_config" => raw_client_config,
          "extra_params" => extra_params,
          "extra_headers" => extra_headers
        } = _app_config,
        refresh_config
      ) do
    response =
      raw_client_config
      |> init()
      |> OAuth2.Client.refresh_token(extra_params, extra_headers)

    case response do
      {:ok, client} ->
        json_mapper = refresh_config["json_response_mapper"]

        token =
          if json_mapper do
            token_data = Jason.decode!(client.token.access_token)

            access_token_path = String.split(json_mapper["access_token"], ".")

            OAuth2.AccessToken.new(%{
              "access_token" => get_in(token_data, access_token_path),
              "expires_in" => token_data["expires_in"],
              "expires" => token_data["expires"],
              "token_type" => token_data["token_type"]
            })
          else
            client.token
          end

        {:ok, token}

      {:error, error_msg} ->
        Logger.error("Error requesting access token: #{inspect(error_msg)}")

        {:error, "Error requesting access token."}
    end
  end

  def get_token(
        %{
          "client_config" => raw_client_config,
          "extra_params" => extra_params,
          "extra_headers" => extra_headers
        } = _app_config,
        step_config
      ) do
    response =
      raw_client_config
      |> init()
      |> OAuth2.Client.get_token(extra_params, extra_headers)

    case response do
      {:ok, client} ->
        json_mapper = step_config["json_response_mapper"]

        token =
          if json_mapper do
            token_data = Jason.decode!(client.token.access_token)

            access_token_path = String.split(json_mapper["access_token"], ".")

            OAuth2.AccessToken.new(%{
              "access_token" => get_in(token_data, access_token_path),
              "expires_in" => token_data["expires_in"],
              "expires" => token_data["expires"],
              "token_type" => token_data["token_type"]
            })
          else
            client.token
          end

        {:ok, token}

      {:error, error_msg} ->
        Logger.error("Error requesting access token: #{inspect(error_msg)}")

        {:error, "Error requesting access token."}
    end
  end

  defp init(raw_client_config) do
    raw_client_config
    |> maybe_parse_token()
    |> parse_client_config()
  end

  defp maybe_parse_token(raw_client_config) do
    if raw_client_config[:token] do
      raw_client_config
      |> Map.update!(:token, &OAuth2.AccessToken.new(&1))
    else
      raw_client_config
    end
  end

  defp parse_client_config(raw_client_config) do
    struct(OAuth2.Client, raw_client_config)
  end
end
