defmodule TaskForestWeb.WorkflowController do
  use TaskForestWeb, :controller

  require Logger

  alias TaskForest.Providers
  alias TaskForest.Workflows
  alias TaskForest.Workflows.ExecutionUtils

  def execute(conn, %{"company" => _company_slug, "workflow" => workflow_id, "inputs" => inputs}) do
    execute_workflow(conn, workflow_id, inputs)
  end

  def handle_webhook(
        conn,
        %{"workflow_id" => workflow_id, "provider_slug" => provider_slug} = params
      ) do
    with workflow <- Workflows.get_workflow_by_id(workflow_id),
         false <- is_nil(workflow),
         provider <- Providers.get_provider_by_slug(provider_slug),
         false <- is_nil(provider),
         {request_type, conn} <-
           maybe_handle_webhook_verification(
             conn,
             workflow.config,
             provider.webhook_config,
             provider_slug
           ) do
      case request_type do
        :verification ->
          conn

        :standard_request ->
          data = Map.drop(params, ["workflow_id", "provider_slug"])
          inputs = Map.put(%{}, "#{provider_slug}_webhook_data", data)

          execute_workflow(conn, workflow_id, inputs)

        _ ->
          Logger.error(
            "Received bad request for webhook reason=#{request_type} workflow_id=#{workflow_id} provider_slug=#{provider_slug} params=#{inspect(params)}"
          )

          conn
          |> put_status(:bad_request)
          |> json(%{status: "error", reason: "Error processing webhook request"})
      end
    else
      _ ->
        Logger.error(
          "Received bad request for webhook workflow_id=#{workflow_id} provider_slug=#{provider_slug} params=#{inspect(params)}"
        )

        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: "Error processing webhook request"})
    end
  end

  def retrieve_execution_results(conn, %{
        "company" => _company_slug,
        "workflow" => _workflow_id,
        "execution_id" => execution_id
      }) do
    case Workflows.retrieve_execution_results(execution_id) do
      {:ok, %{execution: execution, workflow: workflow}} ->
        {final_outputs, intermediate_outputs} =
          ExecutionUtils.parse_outputs(
            execution.outputs,
            workflow.outputs_definition,
            workflow.inputs_definition
          )

        response = %{
          status: "success",
          outputs: final_outputs,
          intermediate_outputs: intermediate_outputs
        }

        conn
        |> put_status(:ok)
        |> json(response)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: reason})
    end
  end

  defp execute_workflow(conn, workflow_id, inputs) do
    case Workflows.execute_workflow(workflow_id, inputs) do
      {:ok, execution_id} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "success", execution_id: execution_id})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: reason})
    end
  end

  defp maybe_handle_webhook_verification(conn, _workflow_config, nil, _provider_slug) do
    {:standard_request, conn}
  end

  defp maybe_handle_webhook_verification(
         conn,
         workflow_config,
         %{"verification" => verification_config} = _provider_webhook_config,
         provider_slug
       ) do
    if is_webhook_verification?(conn, verification_config) do
      handle_webhook_verification(
        verification_config["type"],
        conn,
        workflow_config,
        verification_config,
        provider_slug
      )
    else
      {:standard_request, conn}
    end
  end

  defp is_webhook_verification?(conn, verification_config) do
    [
      "method",
      "query",
      "headers",
      "body",
      "payload_patterns"
    ]
    |> Enum.map(&is_webhook_verification?(&1, conn, verification_config))
    |> Enum.any?()
  end

  defp is_webhook_verification?("method", conn, %{"indicators" => %{"methods" => methods}}) do
    conn.method in methods
  end

  defp is_webhook_verification?(type, conn, %{"indicators" => %{"params" => params}})
       when type in ["query", "headers", "body"] do
    keys =
      case type do
        "query" -> Map.keys(conn.query_params)
        "headers" -> Enum.map(conn.req_headers, fn {key, _} -> key end)
        "body" -> Map.keys(conn.body_params)
      end

    keys
    |> MapSet.new()
    |> MapSet.disjoint?(MapSet.new(params[type]))
    |> Kernel.not()
  end

  defp is_webhook_verification?("payload_patterns", conn, %{
         "indicators" => %{"payload_patterns" => payload_patterns}
       }) do
    conn.body_params
    |> MapSet.new()
    |> MapSet.disjoint?(MapSet.new(payload_patterns))
    |> Kernel.not()
  end

  defp is_webhook_verification?(_check_type, _conn, _verification_config), do: false

  defp handle_webhook_verification(
         "echo",
         conn,
         _workflow_config,
         verification_config,
         _provider_slug
       ) do
    challenge = extract_key(conn, verification_config["source"])

    if challenge do
      content =
        verification_config
        |> get_in(["response", "content"])
        |> String.replace(">>CHALLENGE<<", challenge)

      # TODO: handle building a json response, encoding if content starts with "{"

      response_content_type = get_in(verification_config, ["response", "format"])

      conn =
        conn
        |> put_resp_content_type(response_content_type)
        |> send_resp(:ok, content)
        |> halt()

      {:verification, conn}
    else
      {:failed_verification, conn}
    end
  end

  defp handle_webhook_verification(
         "hmac",
         conn,
         workflow_config,
         verification_config,
         provider_slug
       ) do
    # TODO: implement, getting and decrypting company provider keys
    {:unsupported_verification_type, conn}
  end

  defp handle_webhook_verification(
         "token",
         conn,
         workflow_config,
         verification_config,
         provider_slug
       ) do
    token = extract_key(conn, verification_config["source"])

    provider_webhook_token = get_in(workflow_config, ["webhooks", provider_slug, "token"]) || ""

    if token == provider_webhook_token do
      conn = send_resp(conn, :ok, "OK")

      {:verification, conn}
    else
      {:invalid_verification_token, conn}
    end
  end

  defp handle_webhook_verification(
         _type,
         conn,
         _workflow_config,
         _verification_config,
         _provider_slug
       ) do
    {:invalid_verification_type, conn}
  end

  defp extract_key(conn, %{"location" => "query", "key" => key} = _source_config) do
    conn.query_params[key]
  end

  defp extract_key(conn, %{"location" => "body", "key" => key} = _source_config) do
    conn.body_params[key]
  end

  defp extract_key(conn, %{"location" => "headers", "key" => key} = _source_config) do
    conn
    |> get_req_header(key)
    |> hd()
  end
end
