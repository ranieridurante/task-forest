defmodule TaskForest.Providers do
  import Ecto.Query

  require Logger
  require TaskForest.Providers.DynamicHttpClient

  alias TaskForest.Accounts
  alias TaskForest.Accounts.Workers.Oauth2TokenRefreshWorker
  alias TaskForest.Providers.DynamicHttpClient
  alias TaskForest.Providers.DynamicOAuth2Client
  alias TaskForest.Providers.Provider
  alias TaskForest.Repo

  # TODO: grab host from env var
  @app_host "https://app.plomb.ai"

  def get_providers do
    Repo.all(Provider)
  end

  def get_providers_mapped_by_slug do
    get_providers()
    |> Enum.reduce(%{}, fn provider, acc -> Map.put(acc, provider.slug, provider) end)
  end

  def list_providers_by_slug(slugs) when is_list(slugs) do
    query =
      Provider
      |> where([p], p.slug in ^slugs)
      |> where([p], p.active == true)

    Repo.all(query)
  end

  def get_active_providers do
    Repo.all(Provider, where: [active: true])
  end

  def search_active_providers_by_name(term) do
    query =
      Provider
      |> where([p], p.active == true and ilike(p.name, ^"%#{term}%"))

    Repo.all(query)
  end

  def get_featured_providers do
    Repo.all(Provider, where: [featured: true, active: true])
  end

  def call(
        %{
          task_config: %{"type" => "elixir"},
          task_info: task_info
        } = context
      ) do
    module = Module.concat(["TaskForest.Providers", get_in(context, [:task_config, "module"])])

    if Code.ensure_loaded?(module) and function_exported?(module, :run, 1) do
      try do
        apply(module, :run, [context])
      rescue
        exception ->
          Logger.error("Error running Elixir task: #{inspect(exception)}",
            task: task_info.task_template_name,
            task_name: task_info.name,
            provider: task_info.provider
          )

          {:error, "Error running Elixir task: #{inspect(exception)}"}
      catch
        error ->
          Logger.error("Error running Elixir task: #{inspect(error)}",
            task: task_info.task_template_name,
            task_name: task_info.name,
            provider: task_info.provider
          )

          {:error, "Error running Elixir task: #{inspect(error)}"}
      end
    else
      Logger.error("Elixir task not implemented",
        task: task_info.task_template_name,
        task_name: task_info.name,
        provider: task_info.provider
      )

      {:error, "Elixir task not implemented: #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"}
    end
  end

  def call(
        %{
          "type" => "http_request"
        } = task_config,
        input_params,
        provider_keys \\ %{keys: nil},
        task_info,
        runtime_info
      ) do
    request_name = task_config["request_name"]

    request_host = task_config["request_host"]
    request_uri = task_config["request_uri"]

    request_method = task_config["request_method"]
    request_headers_definition = task_config["request_headers_definition"]
    basic_auth = task_config["basic_auth"]

    request_params_definition = task_config["request_params_definition"] || %{}
    query_params_definition = task_config["query_params_definition"] || %{}

    encoding = task_config["encoding"]

    file_output =
      if task_config["file_output"] do
        %{
          workflow_id: runtime_info.workflow_id,
          execution_id: runtime_info.execution_id,
          company_id: runtime_info.company_id,
          created_by_id: runtime_info.execution_id,
          created_by_type: "execution"
        }
      end

    request_result_mapper = task_config["outputs_mapper"] || %{}
    request_result_validations = task_config["outputs_validations"] || %{}

    with {:ok, request_uri} <- replace_tokens_with_values(request_uri, input_params),
         {:ok, request_host} <- replace_tokens_with_values(request_host, input_params),
         {:ok, provider_keys} <- Accounts.decrypt_provider_keys(provider_keys),
         {:ok, request_params} <-
           build_request_params(
             request_name,
             request_params_definition,
             input_params,
             provider_keys
           ),
         {:ok, query_string} <-
           build_query_string(request_name, query_params_definition, input_params, provider_keys),
         {:ok, basic_auth_header} <- build_basic_auth_header(basic_auth, provider_keys),
         {:ok, request_headers} <-
           build_request_headers(request_headers_definition, basic_auth_header, provider_keys),
         {:ok, response_body} <-
           DynamicHttpClient.perform_request(
             request_name,
             format_request_method(request_method),
             request_uri,
             request_params,
             query_string,
             request_host,
             request_headers,
             encoding: encoding,
             file_output: file_output
           ),
         :ok <-
           validate_request_result(response_body, request_result_validations),
         {:ok, outputs} <- map_request_result(response_body, request_result_mapper) do
      Logger.info("HTTP request successful: #{request_name}")

      {:ok, outputs}
    else
      {:error, error_message} ->
        Logger.error("Error in HTTP request: #{error_message}",
          provider: task_info.provider,
          task: task_info.name,
          task_name: task_info.task_template_name
        )

        {:error, "Error in HTTP request: #{error_message}"}

      error ->
        Logger.error("Error in HTTP request: #{inspect(error)}",
          provider: task_info.provider,
          task: task_info.name,
          task_name: task_info.task_template_name
        )

        {:error, "Error in HTTP request: #{inspect(error)}"}
    end
  end

  defp validate_request_result(_response_body, nil), do: :ok

  defp validate_request_result(response_body, validations) do
    validations =
      Enum.map(validations, fn {validation_key, validation_config} ->
        returned_value = get_in(response_body, String.split(validation_key, "."))

        if validation_config["expected_value"] != nil and
             returned_value != validation_config["expected_value"] do
          "Validation failed for key \"#{validation_key}\": expected #{validation_config["expected_value"]}, got #{returned_value}"
        else
          :ok
        end
      end)
      |> Enum.reject(&(&1 == :ok))

    if Enum.empty?(validations) do
      :ok
    else
      errors = Enum.join(validations, " -  ")

      {:error, "Invalid request result: #{errors}"}
    end
  end

  defp map_request_result(response_body, request_result_mapper) do
    outputs =
      Enum.reduce(request_result_mapper, %{}, fn {output_key, result_json_path}, acc ->
        output_value = extract_value_from_path(result_json_path, response_body)

        Map.put(acc, output_key, output_value)
      end)

    {:ok, outputs}
  rescue
    exception ->
      {:error, "Error mapping request result: #{inspect(exception.message)}"}
  catch
    error ->
      {:error, "Error mapping request result: #{inspect(error)}"}
  end

  defp format_request_method(request_method) do
    request_method
    |> String.downcase()
    |> String.to_atom()
  end

  def extract_value_from_path(full_path, response_body) do
    if String.contains?(full_path, "[]") do
      parse_value_from_list(full_path, response_body)
    else
      get_in(response_body, String.split(full_path, "."))
    end
  end

  defp parse_value_from_list(full_path, response_body) do
    [list_items_path, item_path] = String.split(full_path, "[].", parts: 2)

    list_items = get_in(response_body, String.split(list_items_path, "."))

    list_items
    |> Enum.map(fn item -> extract_value_from_path(item_path, item) end)
    |> List.flatten()
  end

  def build_query_string(request_name, query_params_definition, input_params, provider_keys) do
    query_string =
      Enum.reduce(query_params_definition, "?", fn {key, config}, acc ->
        cond do
          config["provider_key"] != nil ->
            value = Map.get(provider_keys, config["provider_key"])

            if value == nil do
              raise "Provider key not found: #{config["provider_key"]}"
            end

            acc <> "#{key}=#{value}&"

          config["value"] != nil ->
            value = config["value"]

            acc <> "#{key}=#{value}&"

          config["path"] != nil ->
            input_value = get_in(input_params, String.split(config["path"], "."))

            cond do
              input_value == nil && config["required"] ->
                raise "Required input parameter not found for request #{request_name}: #{config["path"]}"

              input_value == nil && config["default"] != nil ->
                acc <> "#{key}=#{config["default"]}&"

              input_value == nil ->
                acc

              is_map(input_value) ->
                Enum.reduce(input_value, acc, fn {inner_key, inner_value}, acc ->
                  acc <> "#{inner_key}=#{inner_value}&"
                end)

              true ->
                input_value
                |> Jason.decode!()
                |> Enum.reduce(acc, fn {inner_key, inner_value}, acc ->
                  acc <> "#{inner_key}=#{inner_value}&"
                end)
            end

          true ->
            input_value = Map.get(input_params, key)

            acc <> "#{key}=#{input_value}&"
        end
      end)

    {:ok, query_string}
  rescue
    exception ->
      {:error, "Error building query string: #{inspect(exception)}"}
  catch
    error ->
      {:error, "Error building query string: #{inspect(error)}"}
  end

  defp build_request_params(request_name, request_params_definition, input_params, provider_keys)
       when is_list(request_params_definition) do
    request_params =
      Enum.reduce(request_params_definition, %{}, fn %{"name" => key} = config, acc ->
        cond do
          config["provider_key"] != nil ->
            value = Map.get(provider_keys, config["provider_key"])

            if value == nil do
              raise "Provider key not found: #{config["provider_key"]}"
            end

            Map.put(acc, key, value)

          config["value"] != nil ->
            Map.put(acc, key, config["value"])

          config["path"] != nil ->
            input_value = get_in(input_params, String.split(config["path"], "."))

            if config["required"] && input_value == nil do
              raise "Required input parameter not found for request #{request_name}: #{config["path"]}"
            end

            Map.put(acc, key, input_value)

          true ->
            input_value = Map.get(input_params, key)

            Map.put(acc, key, input_value)
        end
      end)

    request_params =
      request_params
      |> Enum.reject(fn {key, value} -> value == nil end)
      |> Map.new()

    {:ok, request_params}
  rescue
    exception ->
      {:error, "Error building request params: #{inspect(exception.message)}"}
  catch
    error ->
      {:error, "Error building request params: #{inspect(error)}"}
  end

  defp build_request_params(request_name, request_params_definition, input_params, provider_keys) do
    request_params =
      Enum.reduce(request_params_definition, %{}, fn {key, config}, acc ->
        cond do
          config["provider_key"] != nil ->
            value = Map.get(provider_keys, config["provider_key"])

            if value == nil do
              raise "Provider key not found: #{config["provider_key"]}"
            end

            Map.put(acc, key, value)

          config["value"] != nil ->
            Map.put(acc, key, config["value"])

          config["path"] != nil ->
            input_value = get_in(input_params, String.split(config["path"], "."))

            if config["required"] && input_value == nil do
              raise "Required input parameter not found for request #{request_name}: #{config["path"]}"
            end

            Map.put(acc, key, input_value)

          true ->
            input_value = Map.get(input_params, key)

            Map.put(acc, key, input_value)
        end
      end)

    request_params =
      request_params
      |> Enum.reject(fn {key, value} -> value == nil end)
      |> Map.new()

    {:ok, request_params}
  rescue
    exception ->
      {:error, "Error building request params: #{inspect(exception.message)}"}
  catch
    error ->
      {:error, "Error building request params: #{inspect(error)}"}
  end

  # TODO: refactor to skip the basic auth header if it's not needed
  def build_basic_auth_header(nil, _provider_keys), do: {:ok, nil}

  def build_basic_auth_header(
        %{"username" => username, "password" => %{"path" => password_path}},
        provider_keys
      ) do
    username =
      cond do
        username["path"] != nil ->
          get_in(provider_keys, String.split(username["path"], "."))

        username["value"] != nil ->
          username["value"]

        true ->
          nil
      end

    password = get_in(provider_keys, String.split(password_path, "."))

    try do
      token = Base.encode64("#{username}:#{password}")

      header = {"Authorization", "Basic #{token}"}

      {:ok, header}
    rescue
      exception ->
        {:error, "Error building basic auth header: #{inspect(exception.message)}"}
    catch
      error ->
        {:error, "Error building basic auth header: #{inspect(error)}"}
    end
  end

  def build_request_headers(request_headers_definition, basic_auth_header, provider_keys) do
    headers =
      Enum.reduce(request_headers_definition, %{}, fn {key, config}, acc ->
        case config do
          %{"token_type" => token_type, "provider_key" => provider_key} ->
            key_value = Map.get(provider_keys, provider_key)

            if key_value == nil do
              raise "Provider key not found: #{provider_key}"
            end

            case key do
              "authorization-bearer" ->
                Map.put(acc, "Authorization", "#{token_type} #{key_value}")

              key ->
                Map.put(acc, key, key_value)
            end

          %{"provider_key" => provider_key} ->
            key_value = Map.get(provider_keys, provider_key)

            if key_value == nil do
              raise "Provider key not found: #{provider_key}"
            end

            case key do
              "authorization-bearer" ->
                Map.put(acc, "Authorization", "Bearer #{key_value}")

              key ->
                Map.put(acc, key, key_value)
            end

          config ->
            Map.put(acc, key, config["value"])
        end
      end)
      |> Map.to_list()

    headers =
      if basic_auth_header != nil do
        [basic_auth_header | headers]
      else
        headers
      end

    {:ok, headers}
  rescue
    exception ->
      {:error, "Error building request headers: #{inspect(exception.message)}"}
  catch
    error ->
      {:error, "Error building request headers: #{inspect(error)}"}
  end

  def get_provider(provider_id) do
    Provider
    |> Repo.get(provider_id)
  end

  def get_provider_by_slug(provider_slug, repo \\ Repo) do
    Provider
    |> repo.get_by(slug: provider_slug)
  end

  def delete_provider(provider) do
    Repo.delete(provider)
  end

  def update_provider_changeset(provider, params \\ %{}) do
    Provider.changeset(provider, params)
  end

  def store_provider(provider, params) do
    provider
    |> Provider.changeset(params)
    |> Repo.insert_or_update()
  end

  def build_oauth2_authorization_client_params(
        app_id,
        provider_app_config_definition,
        decrypted_app_config
      ) do
    redirect_uri = "/apps/#{app_id}/callback"

    # Authorization is always the first step
    step_config = hd(provider_app_config_definition["steps"])

    config_defaults = provider_app_config_definition["defaults"] || {}

    host = step_config["host"] || config_defaults["host"]

    # Uebereauth OAuth2 expects an "absolute or relative URL path to the authorization endpoint".
    # https://github.com/ueberauth/oauth2/blob/e8bb2105a6dedaaf423efc1d02b4666cbc8ca43d/lib/oauth2/client.ex#L88
    authorize_uri = step_config["uri"] || "/oauth/authorize"

    client_config =
      %{
        client_id: decrypted_app_config["client_id"],
        site: host,
        authorize_url: authorize_uri,
        redirect_uri: @app_host <> redirect_uri
      }

    extra_params = step_config["extra_params"] || %{}

    extra_params =
      if step_config["state_field"] do
        state =
          encode_oauth2_state(%{
            app_id: app_id
          })

        Map.put(extra_params, step_config["state_field"], state)
      else
        extra_params
      end

    extra_headers = step_config["extra_headers"] || config_defaults["extra_headers"] || []

    %{
      "client_config" => client_config,
      "extra_params" => extra_params,
      "extra_headers" => extra_headers
    }
  end

  def build_oauth2_refresh_client_params(
        app_id,
        decrypted_provider_keys,
        provider_app_config_definition,
        decrypted_app_config
      ) do
    refresh_config = provider_app_config_definition["refresh_step"]

    redirect_uri = "/apps/#{app_id}/callback"

    token_method = (refresh_config["http_method"] || "post") |> String.to_atom()

    config_defaults = provider_app_config_definition["defaults"] || {}

    host = refresh_config["host"] || config_defaults["host"]

    # Ueberauth OAuth2 expects an "absolute or relative URL path to the token endpoint".
    # https://github.com/ueberauth/oauth2/blob/e8bb2105a6dedaaf423efc1d02b4666cbc8ca43d/lib/oauth2/client.ex#L105C19-L105C71
    token_uri = refresh_config["uri"] || "/oauth/token"

    client_secret = decrypted_app_config["client_secret"]

    access_token = decrypted_provider_keys["access_token"]

    two_weeks_ms = 60 * 60 * 24 * 7 * 2 * 1000

    client_config =
      %{
        client_id: decrypted_app_config["client_id"],
        client_secret: client_secret,
        redirect_uri: @app_host <> redirect_uri,
        site: host,
        token: %{
          "access_token" => access_token,
          "expires_in" => two_weeks_ms,
          "token_type" => "bearer",
          "refresh_token" => access_token
        },
        token_method: token_method,
        token_url: token_uri
      }

    extra_params =
      (refresh_config["extra_params"] || %{})
      |> Enum.map(fn {key, value} ->
        loaded_value =
          cond do
            is_map(value) and value["provider_key"] != nil ->
              Map.get(decrypted_provider_keys, value["provider_key"])

            true ->
              {:ok, loaded_value} = replace_tokens_with_values(value, config_defaults)
              loaded_value
          end

        {String.to_atom(key), loaded_value}
      end)
      |> Keyword.new()
      |> Keyword.put(:code, access_token)
      |> Keyword.put(:client_secret, client_secret)

    extra_headers = refresh_config["extra_headers"] || config_defaults["extra_headers"] || []

    %{
      "client_config" => client_config,
      "extra_params" => extra_params,
      "extra_headers" => extra_headers
    }
  end

  def build_oauth2_token_client_params(
        app_id,
        context,
        step_config,
        provider_app_config_definition,
        decrypted_app_config
      ) do
    redirect_uri = "/apps/#{app_id}/callback"

    token_method = (step_config["http_method"] || "post") |> String.to_atom()

    config_defaults = provider_app_config_definition["defaults"] || {}

    host = step_config["host"] || config_defaults["host"]

    # Ueberauth OAuth2 expects an "absolute or relative URL path to the token endpoint".
    # https://github.com/ueberauth/oauth2/blob/e8bb2105a6dedaaf423efc1d02b4666cbc8ca43d/lib/oauth2/client.ex#L105C19-L105C71
    token_uri = step_config["uri"] || "/oauth/token"

    client_secret = decrypted_app_config["client_secret"]

    client_config =
      %{
        client_id: decrypted_app_config["client_id"],
        client_secret: client_secret,
        redirect_uri: @app_host <> redirect_uri,
        site: host,
        token_method: token_method,
        token_url: token_uri
      }

    extra_params =
      (step_config["extra_params"] || %{})
      |> Enum.map(fn {key, value} ->
        {:ok, loaded_value} = replace_tokens_with_values(value, context)

        {String.to_atom(key), loaded_value}
      end)
      |> Keyword.new()
      |> Keyword.put(:code, context["code"])
      |> Keyword.put(:client_secret, client_secret)

    extra_headers = step_config["extra_headers"] || config_defaults["extra_headers"] || []

    %{
      "client_config" => client_config,
      "extra_params" => extra_params,
      "extra_headers" => extra_headers
    }
  end

  def handle_long_lived_oauth2_token(app_id, token) do
    with {:ok, provider_keys} <- Accounts.store_oauth2_access_token(app_id, token.access_token),
         :ok <- Accounts.delete_temporary_oauth2_tokens(app_id) do
      two_weeks_seconds = 60 * 60 * 24 * 7 * 2
      refresh_at = DateTime.from_unix!(token.expires_at - two_weeks_seconds, :second)

      %{
        app_id: app_id,
        provider_keys_id: provider_keys.id
      }
      |> Oauth2TokenRefreshWorker.new(scheduled_at: refresh_at)
      |> Oban.insert()
    else
      {:error, error_message} ->
        Logger.error("Error handling long-lived OAuth2 token: #{inspect(error_message)}")
        {:error, "Error handling long-lived OAuth2 token"}

      _ ->
        Logger.error("Unknown error handling long-lived OAuth2 token")
        {:error, "Error handling long-lived OAuth2 token"}
    end
  end

  def encode_oauth2_state(state) do
    encoded_state =
      state
      |> Jason.encode!()
      |> Base.url_encode64()

    secret_key = Application.get_env(:task_forest, TaskForestWeb.Endpoint)[:secret_key_base]

    signature = :crypto.mac(:hmac, :sha256, secret_key, encoded_state)
    signature_hex = Base.encode16(signature, case: :lower)

    "#{encoded_state}.#{signature_hex}"
  end

  def verify_and_decode_oauth2_state(state) do
    [state_received, received_signature] = String.split(state, ".")

    secret_key = Application.get_env(:task_forest, TaskForestWeb.Endpoint)[:secret_key_base]

    computed_signature =
      :crypto.mac(:hmac, :sha256, secret_key, state_received)
      |> Base.encode16(case: :lower)

    with true <- received_signature == computed_signature,
         {:ok, decoded_json} <- Base.url_decode64(state_received),
         {:ok, state_data} <- Jason.decode(decoded_json) do
      {:ok, state_data}
    else
      {:error, error_msg} ->
        Logger.error("Error verifying and decoding oauth2 state: #{inspect(error_msg)}")
        {:error, "There was an error authenticating with the provider."}

      _ ->
        {:error, "There was an error authenticating with the provider."}
    end
  end

  def refresh_oauth2_token(app_id, provider_keys) do
    with provider <- get_provider(provider_keys.provider_id),
         app <- Accounts.get_app(app_id),
         {:ok, decrypted_app_config} <- Accounts.decrypt_app_config(app),
         {:ok, decrypted_provider_keys} <- Accounts.decrypt_provider_keys(provider_keys),
         %{"client_config" => _client_config} = client_params <-
           build_oauth2_refresh_client_params(
             app.id,
             decrypted_provider_keys,
             provider.app_config_definition,
             decrypted_app_config
           ),
         {:ok, token} <-
           DynamicOAuth2Client.refresh_token(
             client_params,
             provider.app_config_definition["refresh_step"]
           ),
         {:ok, _} <- handle_long_lived_oauth2_token(app.id, token) do
      Accounts.delete_provider_keys(provider_keys.id)
    else
      {:error, error_message} ->
        Logger.error(
          "Error refreshing OAuth2 code for app: #{app_id}, provider_keys_id: #{provider_keys.id} - #{inspect(error_message)}"
        )

        {:error, "Error refreshing OAuth2 code"}

      _ ->
        Logger.error("Unknown error refreshing OAuth2 code for app: #{app_id}, provider_keys_id: #{provider_keys.id}")

        {:error, "Error refreshing OAuth2 code"}
    end
  end

  def process_oauth2_code(%{"app_id" => app_id} = _state, code) do
    with {:ok, %{app: app, provider: provider}} <- Accounts.get_app_with_provider(app_id),
         :ok <- run_oauth2_token_steps(code, app, provider) do
      :ok
    end
  end

  def run_oauth2_token_steps(initial_code, app, provider) do
    [_authorization_step | token_steps] = provider.app_config_definition["steps"]

    execution_context = %{
      "code" => initial_code
    }

    Enum.reduce(token_steps, execution_context, fn step, ctx ->
      with {:ok, _provider_keys} <-
             Accounts.store_temporary_oauth2_code(ctx["code"], provider.id, app.company_id),
           {:ok, decrypted_app_config} <- Accounts.decrypt_app_config(app),
           %{"client_config" => _client_config} = client_params <-
             build_oauth2_token_client_params(
               app.id,
               ctx,
               step,
               provider.app_config_definition,
               decrypted_app_config
             ),
           {:ok, token} <-
             DynamicOAuth2Client.get_token(client_params, step) do
        if token.expires_at do
          handle_long_lived_oauth2_token(app.id, token)
        end

        Map.put(ctx, "code", token.access_token)
      else
        {:error, error_message} ->
          Logger.error(
            "There was an error running OAuth2 Token steps - APP ID #{app.id}, Error message: #{error_message}"
          )

          {:error, "Error retrieving access token"}

        _ ->
          Logger.error("Unknown error running OAuth2 Token steps - APP ID #{app.id}")
          {:error, "Error retrieving access token"}
      end
    end)

    :ok
  end

  def process_oauth2_access_token(app_id, token) do
    Accounts.store_oauth2_access_token(app_id, token)
  end

  def generate_oauth2_authorize_url(company_provider_app_id) do
    with {:ok, %{app: app, provider: provider}} <-
           Accounts.get_app_with_provider(company_provider_app_id),
         false <- is_nil(provider.app_config_definition),
         {:ok, decrypted_app_config} <- Accounts.decrypt_app_config(app),
         %{"client_config" => _client_config} = client_params <-
           build_oauth2_authorization_client_params(
             app.id,
             provider.app_config_definition,
             decrypted_app_config
           ),
         {:ok, authorize_url} <-
           DynamicOAuth2Client.authorize_url(client_params) do
      {:ok, authorize_url}
    else
      {:error, error_message} ->
        Logger.error(
          "Failed to generate OAuth2 authorize URL for provider app: #{company_provider_app_id} - #{inspect(error_message)}"
        )

        {:error, "Unable to authenticate with the provider"}

      _ ->
        Logger.error("Failed to generate OAuth2 authorize URL for provider app: #{company_provider_app_id}")

        {:error, "Unable to authenticate with the provider"}
    end
  end

  defp replace_tokens_with_values(string, context_params) do
    # Params to interpolate are defined as >>PARAM<<
    tokens_regex = ~r/>>[A-Z_]+<</

    try do
      loaded_string =
        String.replace(string, tokens_regex, fn match ->
          token_key =
            match
            |> String.slice(2..-3//1)
            |> String.downcase()

          # Ensure the match gets casted to string
          "#{Map.get(context_params, token_key, match)}"
        end)

      {:ok, loaded_string}
    rescue
      exception ->
        {:error, "Error replacing tokens with values: #{inspect(exception.message)}"}
    catch
      error ->
        {:error, "Error replacing tokens with values: #{inspect(error)}"}
    end
  end
end
