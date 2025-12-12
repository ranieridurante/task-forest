defmodule TaskForest.Providers.DynamicHttpClient do
  defmacro perform_request(
             request_name,
             request_method,
             request_uri,
             request_params,
             query_string,
             api_host,
             headers,
             opts \\ []
           ) do
    quote do
      require Logger

      import Tesla, only: [get: 3, post: 4, put: 4, delete: 3, patch: 3]

      timeout = 120_000
      retry_delay = 1000
      max_retries = 3

      retry_fn = fn
        {:ok, %{status: status}} when status in [400, 500] ->
          Logger.warning("Retrying request: #{unquote(request_name)}")

          true

        {:ok, _} ->
          false

        {:error, error_message} ->
          Logger.warning("Retrying request with error #{inspect(error_message)}: #{unquote(request_name)}")

          true
      end

      opts = unquote(opts)

      middleware = [
        {Tesla.Middleware.BaseUrl, unquote(api_host)},
        {Tesla.Middleware.Headers, unquote(headers)},
        # {Tesla.Middleware.Logger, log_level: :info},
        {Tesla.Middleware.Timeout, timeout: timeout},
        Tesla.Middleware.FollowRedirects,
        {Tesla.Middleware.Retry, delay: retry_delay, max_retries: max_retries, should_retry: retry_fn}
        #  {Tesla.Middleware.Curl, logger_level: :info}
      ]

      adapter = {Tesla.Adapter.Mint, timeout: timeout, transport_opts: [timeout: timeout]}

      client = Tesla.client(middleware, adapter)

      tesla_function = unquote(request_method)

      try do
        encoded_params =
          if opts[:encoding] == "form_urlencoded" do
            URI.encode_query(unquote(request_params))
          else
            Jason.encode!(unquote(request_params))
          end

        function_call =
          if tesla_function in [:get, :delete] do
            apply(Tesla, tesla_function, [
              client,
              # TODO: Check if query_string is working correctly
              unquote(request_uri) <> unquote(query_string),
              [body: encoded_params]
            ])
          else
            apply(Tesla, tesla_function, [client, unquote(request_uri), encoded_params])
          end

        case function_call do
          {:ok, response} ->
            if response.status in 200..399 do
              result =
                case response.body do
                  body when is_binary(body) ->
                    # Handle media files
                    content_type_header =
                      case List.keyfind(response.headers, "content-type", 0) do
                        nil -> nil
                        tuple -> elem(tuple, 0)
                      end

                    content_type =
                      case List.keyfind(response.headers, "content-type", 0) do
                        nil -> nil
                        tuple -> elem(tuple, 1)
                      end

                    byte_size =
                      case List.keyfind(response.headers, "content-length", 0) do
                        nil -> nil
                        tuple -> elem(tuple, 1)
                      end

                    original_filename =
                      case List.keyfind(response.headers, "content-disposition", 0) do
                        {_, disposition} when is_binary(disposition) ->
                          case Regex.run(~r/filename=\"(.+?)\"/, disposition) do
                            [_, filename] -> filename
                            _ -> nil
                          end

                        _ ->
                          nil
                      end

                    if content_type != nil and
                         content_type_header == "content-type" and
                         (content_type == "application/octet-stream" or
                            content_type == "application/pdf" or
                            content_type == "application/zip" or
                            String.starts_with?(content_type, "application/vnd.") or
                            String.starts_with?(content_type, "audio/") or
                            String.starts_with?(content_type, "video/") or
                            String.starts_with?(content_type, "image/")) do
                      if opts[:file_output] do
                        %{
                          company_id: company_id,
                          workflow_id: workflow_id,
                          execution_id: execution_id,
                          created_by_id: created_by_id,
                          created_by_type: created_by_type
                        } = opts[:file_output]

                        file_metadata = %{
                          filename: original_filename,
                          byte_size: byte_size,
                          content_type: content_type
                        }

                        case TaskForest.Files.MediaUpload.store_file_from_binary(
                               response.body,
                               file_metadata,
                               company_id,
                               workflow_id,
                               execution_id,
                               created_by_id,
                               created_by_type
                             ) do
                          {:ok, media_asset} ->
                            file_url = TaskForest.Files.get_media_asset_url(media_asset.id)

                            %{
                              "file" => %{
                                "filename" => media_asset.original_filename,
                                "content_type" => media_asset.content_type,
                                "byte_size" => media_asset.byte_size,
                                "media_asset_id" => media_asset.id,
                                "url" => file_url
                              }
                            }

                          {:error, error} ->
                            Logger.error("Failed to store file: #{inspect(error)}")
                            nil
                        end
                      else
                        Logger.warning(
                          "TaskForest.Providers.DynamicHttpClient - Received unsupported binary, rejecting it to prevent memory issues api_host=#{unquote(api_host)} request_uri=#{unquote(request_uri)}"
                        )

                        nil
                      end
                    else
                      decoded_data = Jason.decode!(body)

                      case decoded_data do
                        # NOTE: wrap JSON array as a map with key "data_list"
                        data when is_list(data) -> %{"data_list" => data}
                        data -> data
                      end
                    end

                  body ->
                    body
                end

              Logger.info("DynamicHTTPClient HTTP request successful: #{unquote(api_host)} - #{unquote(request_name)}")

              {:ok, result}
            else
              Logger.error("DynamicHTTPClient HTTP request failed: #{unquote(api_host)} - #{unquote(request_name)}}")

              {:error, "#{unquote(request_name)} HTTP request failed with status #{inspect(response.status)}}"}
            end

          {:error, error} ->
            Logger.error(
              "DynamicHTTPClient Error performing HTTP request: #{unquote(api_host)} - #{unquote(request_name)}: #{inspect(error)}"
            )

            {:error, "#{unquote(request_name)} Error performing HTTP request: #{inspect(error)}"}
        end
      rescue
        exception ->
          Logger.error("DynamicHTTPClient Error in HTTP request: #{inspect(exception)}")

          {:error, "Error in HTTP request: #{inspect(exception)}"}
      catch
        error ->
          Logger.error("DynamicHTTPClient Error in HTTP request: #{inspect(error)}")

          {:error, "Error in HTTP request: #{inspect(error)}"}
      end
    end
  end
end
