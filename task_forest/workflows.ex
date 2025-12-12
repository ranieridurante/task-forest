defmodule TaskForest.Workflows do
  require Logger

  import Ecto.Query
  import IEx.Helpers, only: [pid: 1]

  alias Ecto.Multi
  alias TaskForest.Accounts.Company
  alias TaskForest.Accounts.UserCompany
  alias TaskForest.Accounts.ProviderKeys
  alias TaskForest.Models
  alias TaskForest.Payments
  alias TaskForest.Providers
  alias TaskForest.Providers.Provider
  alias TaskForest.Repo
  alias TaskForest.Utils
  alias TaskForest.Workflows.Execution
  alias TaskForest.Workflows.GraphUtils
  alias TaskForest.Workflows.MagicForm
  alias TaskForest.Workflows.Triggers
  alias TaskForest.Tasks.Task
  alias TaskForest.Tasks.TaskTemplate
  alias TaskForest.Workflows.Workers.WorkflowBuilder
  alias TaskForest.Workflows.Workflow

  @default_workflow_config %{
    model_id: "gpt-4-turbo",
    max_retries: nil,
    model_params: %{
      temperature: 0.7,
      response_format: %{
        type: "json_object"
      }
    },
    model_provider: "openai"
  }

  # TODO: move to env var or DB table plomb_workflows
  @magic_forms_generator_workflow_id "6f69b3d8-7e05-46d8-ab8c-e537823e3056"

  def execute_workflow(workflow_id, inputs, opts \\ %{}) do
    inputs_hash = hash_inputs(inputs)
    {:ok, execution} = init_execution(workflow_id, inputs, inputs_hash)

    with {:ok, %{workflow: workflow, tasks: tasks, company: company, company_users: company_users}} <-
           get_workflow_with_tasks(workflow_id),
         :ok <- verify_credits_balance(company.id, workflow.graph),
         :ok <- verify_workflow_has_tasks(tasks),
         :ok <- validate_inputs(inputs, workflow.inputs_definition) do
      inputs =
        inputs
        |> Map.put("execution_id", execution.id)
        |> Map.put("company_users", company_users)

      WorkflowBuilder.insert_workflow(
        workflow.id,
        inputs_hash,
        inputs,
        workflow.graph,
        company.config,
        opts
      )

      Logger.info("Workflow #{workflow_id} started with inputs fingerprint: #{inspect(inputs_hash)}")

      {:ok, execution.id}
    else
      {:error, :not_enough_credits} ->
        Logger.error("Not enough credits to execute workflow #{workflow_id}")

        mark_execution_as_cancelled(execution.id, %{
          "error" => "Not enough credits to execute workflow"
        })

        maybe_notify_workflow_cancellation(
          opts["notify_to"],
          execution.id,
          %{"error" => "Not enough credits to execute workflow"}
        )

        {:error, :not_enough_credits}

      {:error, error_message} ->
        Logger.error("Error executing workflow #{workflow_id}: #{inspect(error_message)}")

        outputs = %{
          error: error_message
        }

        mark_execution_as_cancelled(execution.id, outputs)

        maybe_notify_workflow_cancellation(
          opts["notify_to"],
          execution.id,
          outputs
        )

        {:error, error_message}

      error ->
        Logger.error("Unexpected error executing workflow #{workflow_id}: #{inspect(error)}")

        outputs = %{
          error: "#{inspect(error)}"
        }

        mark_execution_as_cancelled(execution.id, outputs)

        maybe_notify_workflow_cancellation(
          opts["notify_to"],
          execution.id,
          outputs
        )

        {:error, "Something went wrong when executing the workflow. Check the App Dashboard for more details."}
    end
  end

  def get_iterator_variables_definition(graph) do
    graph
    |> GraphUtils.get_iterator_variables()
    |> Enum.into(%{}, fn var ->
      {var,
       %{
         "type" => "string_array"
       }}
    end)
  end

  def recalculate_workflow_inputs_and_outputs(
        _inputs,
        _outputs,
        tasks,
        task_templates,
        iterator_variables
      ) do
    acc = %{
      inputs: %{},
      outputs: %{}
    }

    %{inputs: global_inputs, outputs: global_outputs} =
      Enum.reduce(tasks, acc, fn task, acc ->
        task_inputs =
          if is_map(task.inputs_definition) and task.inputs_definition != %{} do
            task.inputs_definition
          else
            task_template = task_templates[task.task_template_id]

            task_template.inputs_definition
          end

        task_outputs =
          if is_map(task.outputs_definition) and task.outputs_definition != %{} do
            task.outputs_definition
          else
            task_template = task_templates[task.task_template_id]

            task_template.outputs_definition
          end

        %{
          inputs: Map.merge(acc.inputs, task_inputs),
          outputs: Map.merge(acc.outputs, task_outputs)
        }
      end)

    iterator_variables = Map.keys(iterator_variables)

    singularized_iterator_variables = Enum.map(iterator_variables, &Utils.singularize/1)

    variables_to_remove = ["iterator_index", "prompt"] ++ singularized_iterator_variables

    global_inputs_keys =
      global_inputs
      |> Map.keys()
      # Remove iterator variables from inputs
      |> Enum.reject(fn key -> Enum.member?(variables_to_remove, key) end)
      |> MapSet.new()

    global_outputs_keys =
      global_outputs
      |> Map.keys()
      # Remove iterator variables from outputs
      |> Enum.reject(fn key -> Enum.member?(iterator_variables, key) end)
      |> MapSet.new()

    missing_inputs = MapSet.difference(global_inputs_keys, global_outputs_keys)

    missing_outputs = MapSet.difference(global_outputs_keys, global_inputs_keys)

    new_inputs =
      Enum.reduce(missing_inputs, %{}, fn key, acc ->
        Map.put(acc, key, global_inputs[key])
      end)

    new_outputs =
      Enum.reduce(missing_outputs, %{}, fn key, acc ->
        Map.put(acc, key, global_outputs[key])
      end)

    {new_inputs, new_outputs}
  end

  def retrieve_execution_results(execution_id) do
    Multi.new()
    |> Multi.run(:execution, fn repo, _changes ->
      query = from(e in Execution, where: e.id == ^execution_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:workflow, fn repo, %{execution: execution} ->
      query = from(w in Workflow, where: w.id == ^execution.workflow_id)
      {:ok, repo.one(query)}
    end)
    |> Repo.transaction()
  end

  def get_task_context_by_id(task_id) do
    Multi.new()
    |> Multi.run(:task, fn repo, _changes ->
      query = from(t in Task, where: t.id == ^task_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:task_template, fn repo, %{task: task} ->
      query = from(tt in TaskTemplate, where: tt.id == ^task.task_template_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:provider, fn repo, %{task_template: task_template} ->
      query = from(p in Provider, where: p.slug == ^task_template.provider_slug)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:workflow, fn repo, %{task: task} ->
      query = from(w in Workflow, where: w.id == ^task.workflow_id)
      {:ok, repo.one(query)}
    end)
    # TODO: delete after adding better api keys storage
    |> Multi.run(:company, fn repo, %{workflow: workflow} ->
      query = from(c in Company, where: c.id == ^workflow.company_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:provider_keys, fn repo, %{company: company, task_template: task_template} ->
      query =
        from(p in ProviderKeys,
          join: pr in Provider,
          on: pr.id == p.provider_id,
          where: p.company_id == ^company.id,
          where: pr.slug == ^task_template.provider_slug
        )
        # TODO: handle multiple provider keys
        |> first(:inserted_at)

      {:ok, repo.one(query)}
    end)
    |> Repo.transaction()
  end

  def execute_task(
        %{
          task: task,
          task_template: %{config: %{"type" => "elixir"}} = task_template,
          provider: provider
        } = context
      ) do
    Logger.debug("Executing task_id=#{task.id} for task_template_id=#{task_template.id}")

    task_info = %{
      task_template_name: task_template.name,
      name: task.name,
      provider: provider.name
    }

    error_message_prefix =
      "#{task_info.provider} - #{task_info.task_template_name} - #{task_info.name}"

    with task_config <- Map.merge(task_template.config, task.config_overrides || %{}),
         context <- Map.put(context, :task_config, task_config),
         {:ok, inputs} <- maybe_load_prompt_template(context.inputs),
         context <- Map.put(context, :inputs, inputs),
         context <- Map.put(context, :task_info, task_info),
         {:ok, results} <- Providers.call(context) do
      {:ok, results}
    else
      {:error, error_message} ->
        Logger.error("Error executing task_id=#{task.id}: #{error_message}",
          provider: provider.name,
          task: task_template.name,
          task_name: task.name
        )

        {:error, "#{error_message_prefix} Something went wrong executing task: #{error_message}"}

      error ->
        Logger.error("Error executing task_id=#{task.id}: #{inspect(error)}",
          provider: provider.name,
          task: task_template.name,
          task_name: task.name
        )

        {:error, "#{error_message_prefix} Something went wrong executing task: #{inspect(error)}"}
    end
  end

  def execute_task(
        %{
          task: task,
          task_template: %{config: %{"type" => "http_request"}} = task_template,
          provider: provider,
          workflow_id: workflow_id,
          execution_id: execution_id,
          company_id: company_id
        } = context
      ) do
    Logger.debug("Executing task_id=#{task.id} for task_template_id=#{task_template.id}")

    task_info = %{
      task_template_name: task_template.name,
      name: task.name,
      provider: provider.name
    }

    runtime_info = %{
      workflow_id: workflow_id,
      execution_id: execution_id,
      company_id: company_id
    }

    error_message_prefix =
      "#{task_info.provider} - #{task_info.task_template_name} - #{task_info.name}"

    with task_config <- Map.merge(task_template.config, task.config_overrides || %{}),
         {:ok, inputs} <- maybe_load_prompt_template(context.inputs),
         {:ok, request_body} <-
           Providers.call(task_config, inputs, context.provider_keys, task_info, runtime_info) do
      {:ok, request_body}
    else
      {:error, error_message} ->
        Logger.error("Error executing task_id=#{task.id}: #{error_message}",
          provider: provider.name,
          task: task_template.name,
          task_name: task.name
        )

        {:error, error_message}

      error ->
        Logger.error("Error executing task_id=#{task.id}: #{inspect(error)}",
          provider: provider.name,
          task: task_template.name,
          task_name: task.name
        )

        {:error, "#{error_message_prefix} Something went wrong executing task: #{inspect(error)}"}
    end
  end

  def execute_task(
        %{
          task: task,
          task_template: %{config: %{"type" => "model"}} = task_template,
          provider: provider
        } = context
      ) do
    Logger.debug("Executing task_id=#{task.id} for task_template_id=#{task_template.id}")

    task_info = %{
      task_template_name: task_template.name,
      name: task.name,
      provider: provider.name
    }

    model_params =
      Map.merge(task_template.config["model_params"], task.config_overrides["model_params"])

    task_config =
      task_template.config
      |> Map.merge(task.config_overrides)
      |> Map.put("model_params", model_params)

    model_params = Utils.string_map_to_keyword_list(task_config["model_params"])

    prompt = get_in(task_config, ["model_params", "prompt"])

    error_message_prefix =
      "#{task_info.provider} - #{task_info.task_template_name} - #{task_info.name}"

    with :ok <- validate_inputs(context.inputs, prompt),
         {:ok, loaded_prompt} <-
           build_model_prompt(prompt, context.inputs, task.outputs_definition),
         inputs <- Map.put(context.inputs, "loaded_prompt", loaded_prompt),
         model_params <- %{
           model_id: task_config["model_id"],
           model_params: model_params,
           provider_keys: context.provider_keys,
           inputs: inputs
         },
         {:ok, task_outputs} <-
           Models.call_model(
             task_template.provider_slug,
             model_params,
             task_info
           ) do
      Logger.info(
        "Successful task execution",
        task: task_info.task_template_name,
        task_name: task_info.name,
        provider: task_info.provider
      )

      {:ok, task_outputs}
    else
      {:error, error_message} ->
        Logger.error("Error executing task_id=#{task.id}: #{error_message}",
          provider: provider.name,
          task: task_template.name,
          task_name: task.name
        )

        {:error, "#{error_message_prefix} Error executing task: #{error_message}"}

      error ->
        Logger.error("Error executing task_id=#{task.id}: #{inspect(error)}",
          provider: provider.name,
          task: task_template.name,
          task_name: task.name
        )

        {:error, "#{error_message_prefix} Something went wrong executing task: #{inspect(error)}"}
    end
  end

  def get_max_concurrency_by_task_id_list(task_id_list) do
    task_id_list = Enum.filter(task_id_list, &Utils.is_uuid?/1)

    query =
      from(t in Task,
        where: t.id in ^task_id_list,
        left_join: tt in TaskTemplate,
        on: t.task_template_id == tt.id,
        select: %{
          t.id => tt.config["max_concurrency"]
        }
      )

    query
    |> Repo.all()
    |> Enum.reduce(%{}, fn map, acc ->
      Map.merge(acc, map)
    end)
  end

  def mark_execution_as_completed(execution_id, outputs) do
    execution = Repo.get_by(Execution, id: execution_id)

    store_execution(%{status: "completed", outputs: outputs}, execution)
  end

  def mark_recent_execution_as_cancelled(workflow_id, inputs_hash, errors) do
    case get_recent_execution_by_input_hash(workflow_id, inputs_hash) do
      nil ->
        {:error, "No recent execution found for workflow #{workflow_id} and inputs hash #{inputs_hash}"}

      execution ->
        mark_execution_as_cancelled(execution.id, errors)
    end
  end

  def mark_execution_as_cancelled(execution_id, errors) do
    execution = Repo.get_by(Execution, id: execution_id)

    store_execution(%{status: "cancelled", outputs: errors}, execution)
  end

  def get_company_workflows(company_id) do
    query =
      from(w in Workflow,
        where: w.company_id == ^company_id and is_nil(w.template_reference_for_id),
        order_by: [desc: w.inserted_at],
        preload: [:workflow_template]
      )

    Repo.all(query)
  end

  def update_workflow_graph(workflow_id, data, update_fn) do
    Multi.new()
    |> Multi.run(:workflow, fn repo, _params ->
      query = from(w in Workflow, where: w.id == ^workflow_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:updated_workflow, fn repo, %{workflow: workflow} ->
      new_workflow_graph = update_fn.(workflow.graph, data)

      store_workflow(%{graph: new_workflow_graph}, workflow, repo)
    end)
    |> Repo.transaction()
  end

  def update_workflow(workflow_id, workflow_params) do
    results =
      Multi.new()
      |> Multi.run(:workflow, fn repo, _changes ->
        {:ok, repo.get(Workflow, workflow_id)}
      end)
      |> Multi.run(:updated_workflow, fn repo, %{workflow: workflow} ->
        store_workflow(workflow_params, workflow, repo)
      end)
      |> Repo.transaction()

    case results do
      {:ok, %{updated_workflow: workflow}} -> {:ok, workflow}
      {:error, _changeset} -> {:error, "Failed to update workflow"}
    end
  end

  def create_task(task_params) do
    # NOTE: if the task has a prompt, add any tokens to the inputs_definition
    maybe_prompt =
      get_in(task_params, ["inputs_definition", "prompt", "value"]) ||
        get_in(task_params, ["config_overrides", "model_params", "prompt"])

    task_params =
      if maybe_prompt do
        prompt_inputs_def =
          maybe_prompt
          |> get_prompt_tokens()
          |> Enum.reduce(%{}, fn token, acc ->
            Map.put(acc, token, %{"type" => "string"})
          end)

        Map.put(
          task_params,
          "inputs_definition",
          prompt_inputs_def
        )
      else
        Map.put(task_params, "inputs_definition", task_params["inputs_definition"])
      end

    Logger.debug("Creating task with params: #{inspect(task_params)} ")

    results =
      Multi.new()
      |> Multi.run(:task, fn repo, _changes ->
        store_task(task_params, %Task{}, repo)
      end)
      |> Multi.run(:task_template, fn repo, %{task: task} ->
        query = from(tt in TaskTemplate, where: tt.id == ^task.task_template_id)
        {:ok, repo.one(query)}
      end)
      |> Multi.merge(fn %{task: task} ->
        full_workflow_multi_query(task.workflow_id)
      end)
      |> Multi.run(:updated_workflow, fn repo,
                                         %{
                                           workflow: workflow,
                                           task: task,
                                           task_template: task_template,
                                           tasks: tasks,
                                           task_templates: task_templates
                                         } ->
        new_workflow_graph = GraphUtils.add_appending_task_to_raw_graph(workflow.graph, task.id)

        updated_tasks = tasks ++ [task]

        updated_task_templates =
          Map.merge(task_templates, %{task.task_template_id => task_template})

        iterator_variables_definition = get_iterator_variables_definition(new_workflow_graph)

        # TODO: redesign worklow inputs and outputs
        # {new_inputs, new_outputs} =
        #  recalculate_workflow_inputs_and_outputs(
        #    workflow.inputs_definition,
        #   workflow.outputs_definition,
        #   updated_tasks,
        #     updated_task_templates,
        #     iterator_variables_definition
        #   )

        store_workflow(
          %{
            graph: new_workflow_graph,
            inputs_definition: workflow.inputs_definition,
            outputs_definition: workflow.outputs_definition
          },
          workflow,
          repo
        )
      end)
      |> Repo.transaction()

    case results do
      {:ok, result} -> {:ok, result}
      {:error, _changeset} -> {:error, "Failed to create task"}
    end
  end

  def create_workflow(params) do
    Multi.new()
    |> Multi.run(:workflow, fn repo, _changes ->
      params = Map.put(params, "config", @default_workflow_config)

      store_workflow(params, %Workflow{}, repo)
    end)
    |> Repo.transaction()
  end

  def maybe_notify_workflow_cancellation(nil, _execution_id, _outputs), do: :ok

  def maybe_notify_workflow_cancellation(notify_to_pid, execution_id, outputs) do
    send(
      pid(notify_to_pid),
      {:workflow_cancelled,
       %{
         execution_id: execution_id,
         outputs: outputs
       }}
    )
  end

  defp init_execution(workflow_id, inputs, inputs_hash) do
    params = %{
      workflow_id: workflow_id,
      inputs: inputs,
      status: "started",
      inputs_hash: inputs_hash
    }

    case store_execution(params) do
      {:ok, execution} -> {:ok, execution}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def repeat_execution(execution_id, opts \\ %{}) do
    with {:ok, execution} <- get_execution_by_id(execution_id),
         {:ok, new_execution_id} <-
           execute_workflow(execution.workflow_id, execution.inputs, opts),
         {:ok, new_execution} <- get_execution_by_id(new_execution_id) do
      {:ok, new_execution}
    else
      {:error, :not_enough_credits} ->
        Logger.error("Not enough credits to repeat execution #{execution_id}")

        {:error, "Not enough credits to repeat execution"}

      {:error, error_message} ->
        Logger.error("Error repeating execution: #{inspect(error_message)}")

        {:error, "Error repeating execution: #{inspect(error_message)}"}

      error ->
        Logger.error("Unexpected error repeating execution: #{inspect(error)}")

        {:error, "Unexpected error repeating execution: #{inspect(error)}"}
    end
  end

  def get_execution_by_id(execution_id) do
    case Repo.get_by(Execution, id: execution_id) do
      nil -> {:error, "Execution not found"}
      execution -> {:ok, execution}
    end
  end

  # TODO: support all cases listed in fill_prompt_template/2
  def get_prompt_tokens(prompt) do
    prompt_tokens_regex()
    |> Regex.scan(prompt)
    |> List.flatten()
    |> Enum.map(fn term ->
      term
      |> String.slice(2..-3//1)
      |> String.downcase()
    end)
  end

  defp validate_inputs(inputs, prompt) when is_binary(prompt) do
    oban_worker_input_keys = [
      "execution_id",
      "task_id",
      "workflow_id",
      "inputs_hash",
      "workflow_opts"
    ]

    prompt_tokens =
      prompt
      |> get_prompt_tokens()
      |> Enum.reject(fn token ->
        String.contains?(token, ".") or String.contains?(token, "[")
      end)
      |> MapSet.new()

    inputs_keys =
      inputs
      |> Map.keys()
      |> Enum.reject(fn key ->
        Enum.member?(oban_worker_input_keys, key)
      end)
      |> MapSet.new()

    case MapSet.subset?(prompt_tokens, inputs_keys) do
      true ->
        :ok

      false ->
        Logger.error("inputs_keys: #{inspect(inputs_keys)}")
        Logger.error("prompt_tokens: #{inspect(prompt_tokens)}")

        {:error, "Invalid inputs - received: #{inspect(inputs_keys)}, missing: #{inspect(prompt_tokens)}"}
    end
  end

  defp validate_inputs(inputs, inputs_definition) when is_map(inputs_definition) do
    # TODO: check for types and other constraints field by field
    [inputs_keys, inputs_definition_keys] =
      Enum.map([inputs, inputs_definition], fn x ->
        x
        |> Map.keys()
        |> MapSet.new()
      end)

    case MapSet.subset?(inputs_definition_keys, inputs_keys) do
      true ->
        :ok

      false ->
        Logger.error("inputs_keys: #{inspect(inputs_keys)}")
        Logger.error("inputs_definition_keys: #{inspect(inputs_definition_keys)}")

        {:error, "Invalid inputs - received: #{inspect(inputs_keys)}, missing: #{inspect(inputs_definition_keys)}"}
    end
  end

  defp maybe_load_prompt_template(%{"prompt" => prompt} = inputs) when is_binary(prompt) do
    if String.contains?(prompt, ">>") do
      with :ok <- validate_inputs(inputs, prompt),
           {:ok, updated_prompt} <- fill_prompt_template(prompt, inputs),
           updated_inputs <- Map.put(inputs, "prompt", updated_prompt) do
        {:ok, updated_inputs}
      else
        {:error, error_message} -> {:error, "Error loading prompt template: #{error_message}"}
        error -> {:error, "Error loading prompt template: #{inspect(error)}"}
      end
    else
      {:ok, inputs}
    end
  end

  defp maybe_load_prompt_template(inputs), do: {:ok, inputs}

  defp build_model_prompt(prompt, inputs, outputs_definition) do
    case fill_prompt_template(prompt, inputs) do
      {:ok, loaded_prompt} -> {:ok, add_outputs_to_prompt(loaded_prompt, outputs_definition)}
      {:error, _} = error -> error
    end
  end

  # TODO: move to prompts module
  def add_outputs_to_prompt(prompt, outputs_definition) do
    """
    #{prompt}

    RESPONSE
    ###
    IMPORTANT: Your response MUST be a valid JSON object and nothing else. Do not include any explanations, notes, or additional text outside the JSON structure. Do not use code blocks, backticks, or any other formatting.

    Strictly adhere to the following format:
    {
      #{Enum.map(outputs_definition, fn {key, value} -> "\"#{key}\": <#{key} as #{value["type"]}>" end) |> Enum.join(",\n")}
    }

    Ensure that:
    1. All keys are enclosed in double quotes.
    2. All string values are enclosed in double quotes.
    3. Numbers are not quoted.
    4. Boolean values are lowercase (true or false) and not quoted.
    5. Null values are represented as null without quotes.
    6. Arrays are enclosed in square brackets [].
    7. Nested objects are properly formatted.

    If you cannot provide a value for a field, use null.

    Your entire response should be a single, valid JSON object without any additional text or formatting.
    """
  end

  defp prompt_tokens_regex, do: ~r/>>[A-Z_.]+(?:[A-Z_]+)(?:\[[A-Z_].+(?:[A-Z_]+)\])?<</

  def fill_prompt_template(prompt, inputs) do
    # Available token formats:
    # >>TEST<<
    # >>ANOTHER_TEST<<
    # >>TEST[MY_VAR]<<
    # >>TEST.SUBTEST[ANOTHER_TEST]<<
    # >>TEST.SUBTEST[ANOTHER_TEST.SUBTEST]<<
    # >>TEST.ANOTHER_TEST.ANOTHER_VAR<<
    tokens_regex = prompt_tokens_regex()

    try do
      loaded_prompt =
        String.replace(prompt, tokens_regex, fn match ->
          token_key =
            match
            |> String.slice(2..-3//1)
            |> String.downcase()

          replacement =
            cond do
              String.contains?(token_key, "[") ->
                [list_key, index_key] = String.split(token_key, "[")
                index_key = String.slice(index_key, 0..-2//1)

                list = get_in(inputs, String.split(list_key, "."))

                index = get_in(inputs, String.split(index_key, "."))

                index =
                  cond do
                    is_integer(index) -> index
                    is_binary(index) -> String.to_integer(index)
                    true -> nil
                  end

                # NOTE: Decrease index by 1 to match 0-based indexing
                Enum.at(list, index - 1) || match

              true ->
                get_in(inputs, String.split(token_key, ".")) || match
            end

          Jason.encode!(replacement)
        end)

      {:ok, loaded_prompt}
    rescue
      exception -> {:error, "Error loading prompt template: #{inspect(exception)}"}
    catch
      error -> {:error, "Error loading prompt template: #{inspect(error)}"}
    end
  end

  def update_task(task_id, original_task_params) do
    # NOTE: if the task has a prompt, add any tokens to the inputs_definition
    maybe_prompt =
      get_in(original_task_params, ["inputs_definition", "prompt", "value"]) ||
        get_in(original_task_params, ["config_overrides", "model_params", "prompt"])

    task_params =
      if maybe_prompt do
        base_inputs_def = %{
          "prompt" => %{"type" => "text", "value" => maybe_prompt}
        }

        prompt_inputs_def =
          maybe_prompt
          |> get_prompt_tokens()
          |> Enum.reduce(base_inputs_def, fn token, acc ->
            Map.put(acc, token, %{"type" => "string"})
          end)

        Map.put(
          original_task_params,
          "inputs_definition",
          prompt_inputs_def
        )
      else
        Map.put(
          original_task_params,
          "inputs_definition",
          original_task_params["inputs_definition"]
        )
      end

    results =
      Multi.new()
      |> Multi.run(:task, fn repo, _changes ->
        {:ok, repo.get(Task, task_id)}
      end)
      |> Multi.run(:task_template, fn repo, %{task: task} ->
        query = from(tt in TaskTemplate, where: tt.id == ^task.task_template_id)
        {:ok, repo.one(query)}
      end)
      |> Multi.run(:updated_task, fn repo, %{task: task} ->
        store_task(task_params, task, repo)
      end)
      |> Multi.merge(fn %{task: task} ->
        full_workflow_multi_query(task.workflow_id)
      end)
      |> Multi.run(:updated_workflow, fn repo,
                                         %{
                                           workflow: workflow,
                                           updated_task: updated_task,
                                           tasks: tasks,
                                           task_templates: task_templates
                                         } ->
        iterator_variables_definition = get_iterator_variables_definition(workflow.graph)

        updated_tasks =
          tasks
          |> Enum.reject(fn t -> t.id == updated_task.id end)
          |> Kernel.++([updated_task])

        # TODO: redesign workflow inputs and outputs
        #    {new_inputs, new_outputs} =
        #     recalculate_workflow_inputs_and_outputs(
        #      workflow.inputs_definition,
        #     workflow.outputs_definition,
        #    updated_tasks,
        #    task_templates,
        #    iterator_variables_definition
        #   )

        store_workflow(
          %{
            inputs_definition: workflow.inputs_definition,
            outputs_definition: workflow.outputs_definition
          },
          workflow,
          repo
        )
      end)
      |> Repo.transaction()

    case results do
      {:ok, result} -> {:ok, result}
      {:error, _changeset} -> {:error, "Failed to update task"}
    end
  end

  def delete_iterator(iterator_id, workflow_id) do
    results =
      Multi.new()
      |> Multi.run(:workflow, fn repo, _changes ->
        query = from(w in Workflow, where: w.id == ^workflow_id)
        {:ok, repo.one(query)}
      end)
      |> Multi.run(:updated_workflow, fn repo, %{workflow: workflow} ->
        new_workflow_graph =
          GraphUtils.remove_iterator_from_raw_graph(workflow.graph, iterator_id)

        store_workflow(%{graph: new_workflow_graph}, workflow, repo)
      end)
      |> Repo.transaction()

    case results do
      {:ok, %{updated_workflow: new_workflow, workflow: workflow}} ->
        {:ok,
         %{
           iterator_id: iterator_id,
           updated_graph: new_workflow.graph,
           original_graph: workflow.graph
         }}

      {:error, _changeset} ->
        {:error, "Failed to delete iterator"}
    end
  end

  def delete_converger(converger_id, workflow_id) do
    results =
      Multi.new()
      |> Multi.run(:workflow, fn repo, _changes ->
        query = from(w in Workflow, where: w.id == ^workflow_id)
        {:ok, repo.one(query)}
      end)
      |> Multi.run(:updated_workflow, fn repo, %{workflow: workflow} ->
        new_workflow_graph = GraphUtils.remove_converger_from_raw_graph(workflow.graph, converger_id)

        store_workflow(%{graph: new_workflow_graph}, workflow, repo)
      end)
      |> Repo.transaction()

    case results do
      {:ok, %{updated_workflow: new_workflow, workflow: workflow}} ->
        {:ok, %{converger_id: converger_id, updated_graph: new_workflow.graph, original_graph: workflow.graph}}

      {:error, _changeset} ->
        {:error, "Failed to delete converger"}
    end
  end

  def get_workflow_magic_forms(workflow_id) do
    query = from(mf in MagicForm, where: mf.workflow_id == ^workflow_id)
    Repo.all(query)
  end

  def get_magic_form_by_id(magic_form_id, repo \\ Repo) do
    repo.get(MagicForm, magic_form_id)
  end

  def increase_magic_form_views(magic_form_id) do
    Multi.new()
    |> Multi.run(:set_tx_isolation_level, fn repo, _ ->
      repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;")
      {:ok, nil}
    end)
    |> Multi.run(:magic_form, fn repo, _ ->
      {:ok, get_magic_form_by_id(magic_form_id, repo)}
    end)
    |> Multi.run(:updated_magic_form, fn repo, %{magic_form: magic_form} ->
      magic_form
      |> MagicForm.changeset(%{views_count: magic_form.views_count + 1})
      |> repo.update()
    end)
    |> Repo.transaction()
  end

  def increase_magic_form_submissions(magic_form_id) do
    Multi.new()
    |> Multi.run(:set_tx_isolation_level, fn repo, _ ->
      repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;")
      {:ok, nil}
    end)
    |> Multi.run(:magic_form, fn repo, _ ->
      {:ok, get_magic_form_by_id(magic_form_id, repo)}
    end)
    |> Multi.run(:updated_magic_form, fn repo, %{magic_form: magic_form} ->
      magic_form
      |> MagicForm.changeset(%{submissions_count: magic_form.submissions_count + 1})
      |> repo.update()
    end)
    |> Repo.transaction()
  end

  def create_magic_form(workflow_id) do
    workflow = get_workflow_by_id(workflow_id)

    params = %{
      workflow_id: workflow_id,
      inputs_definition: workflow.inputs_definition,
      name: workflow.name
    }

    %MagicForm{}
    |> MagicForm.changeset(params)
    |> Repo.insert()
  end

  def update_magic_form(magic_form, params) do
    magic_form
    |> MagicForm.changeset(params)
    |> Repo.update()
  end

  def delete_magic_form(magic_form_id) do
    magic_form_id
    |> get_magic_form_by_id()
    |> Repo.delete()
  end

  # TODO: soft delete instead when prototype feels more stable
  # TODO: Template Library, delete workflow_template
  def delete_workflow(workflow_id) do
    Multi.new()
    |> Multi.run(:delete_tasks, fn repo, _ ->
      query =
        from(t in Task,
          where: t.workflow_id == ^workflow_id and t.is_template_reference == false
        )

      {:ok, repo.delete_all(query)}
    end)
    |> Multi.run(:delete_executions, fn repo, _ ->
      query = from(e in Execution, where: e.workflow_id == ^workflow_id)
      {:ok, repo.delete_all(query)}
    end)
    |> Multi.run(:workflow, fn repo, _ ->
      query = from(w in Workflow, where: w.id == ^workflow_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:delete_workflow, fn repo, %{workflow: workflow} ->
      repo.delete(workflow)
    end)
    |> Repo.transaction()
  end

  def delete_task(task_id) do
    results =
      Multi.new()
      |> Multi.run(:task, fn repo, _changes ->
        {:ok, repo.get(Task, task_id)}
      end)
      |> Multi.merge(fn %{task: task} ->
        full_workflow_multi_query(task.workflow_id)
      end)
      |> Multi.run(:updated_workflow, fn repo,
                                         %{
                                           workflow: workflow,
                                           task: task,
                                           tasks: tasks,
                                           task_templates: task_templates
                                         } ->
        new_workflow_graph = GraphUtils.remove_task_from_raw_graph(workflow.graph, task.id)

        updated_tasks = Enum.reject(tasks, fn t -> t.id == task.id end)

        iterator_variables_definition = get_iterator_variables_definition(new_workflow_graph)

        # TODO: redesign workflow inputs and outputs
        #  {new_inputs, new_outputs} =
        #    recalculate_workflow_inputs_and_outputs(
        #      workflow.inputs_definition,
        #      workflow.outputs_definition,
        #     updated_tasks,
        #     task_templates,
        #     iterator_variables_definition
        #   )

        store_workflow(
          %{
            graph: new_workflow_graph,
            inputs_definition: workflow.inputs_definition,
            outputs_definition: workflow.outputs_definition
          },
          workflow,
          repo
        )
      end)
      |> Multi.run(:deleted_task, fn repo, %{task: task} ->
        repo.delete(task)
      end)
      |> Repo.transaction()

    case results do
      {:ok, _} -> {:ok, task_id}
      {:error, _changeset} -> {:error, "Failed to delete task"}
    end
  end

  defp full_workflow_multi_query(workflow_id) do
    Multi.new()
    |> Multi.run(:workflow, fn repo, _ ->
      query =
        from(w in Workflow, where: w.id == ^workflow_id)

      {:ok, repo.one(query)}
    end)
    |> Multi.run(:company, fn repo, %{workflow: workflow} ->
      query = from(c in Company, where: c.id == ^workflow.company_id)
      {:ok, repo.one(query)}
    end)
    |> Multi.run(:company_users, fn repo, %{company: company} ->
      query = from(cu in UserCompany, where: cu.company_id == ^company.id, preload: [:user])
      {:ok, Enum.map(repo.all(query), & &1.user)}
    end)
    |> Multi.run(:tasks, fn repo, %{workflow: workflow} ->
      query =
        from(t in Task, where: t.workflow_id == ^workflow.id and t.is_template_reference == false)

      {:ok, repo.all(query)}
    end)
    |> Multi.run(:task_templates, fn repo, %{tasks: tasks} ->
      task_template_ids =
        tasks
        |> Enum.map(& &1.task_template_id)
        |> Enum.uniq()

      query =
        from(tt in TaskTemplate,
          where: tt.id in ^task_template_ids,
          select: %{
            tt.id => tt
          }
        )

      task_templates =
        query
        |> repo.all()
        |> Enum.reduce(%{}, fn tt, acc -> Map.merge(acc, tt) end)

      {:ok, task_templates}
    end)
  end

  def get_workflow_with_tasks(workflow_id) do
    workflow_id
    |> full_workflow_multi_query()
    |> Repo.transaction()
  end

  def get_reference_workflow(referenced_workflow_id, repo \\ Repo) do
    repo.get_by(Workflow, template_reference_for_id: referenced_workflow_id)
  end

  def get_executions(workflow_id, opts \\ []) do
    page_size = opts[:page_size] || 10
    page = opts[:page] || 1

    offset = (page - 1) * page_size

    query =
      from(e in Execution,
        where: e.workflow_id == ^workflow_id,
        order_by: [desc: e.inserted_at],
        limit: ^page_size,
        offset: ^offset
      )

    query =
      if opts[:omit_inputs_outputs] do
        query
        |> select([e], %{
          id: e.id,
          status: e.status,
          inserted_at: e.inserted_at,
          updated_at: e.updated_at
        })
      else
        query
      end

    Repo.all(query)
  end

  def get_workflow_by_id(workflow_id, repo \\ Repo) do
    query = from(w in Workflow, where: w.id == ^workflow_id)
    repo.one(query)
  end

  defp hash_inputs(inputs) do
    inputs
    |> :erlang.phash2()
    |> to_string()
  end

  defp get_recent_execution_by_input_hash(workflow_id, inputs_hash) do
    one_hour_ago =
      DateTime.utc_now()
      |> DateTime.add(-1, :hour)

    query =
      from(e in Execution,
        where: e.workflow_id == ^workflow_id and e.inputs_hash == ^inputs_hash,
        where: e.inserted_at > ^one_hour_ago,
        where: e.status != "cancelled",
        limit: 1
      )

    Repo.one(query)
  end

  def verify_workflow_has_tasks(tasks) do
    if Enum.empty?(tasks) do
      {:error, "You tried to run a workflow, but it has no tasks. Add some first in the Canvas."}
    else
      :ok
    end
  end

  def store_task(task_params, task, repo \\ Repo) do
    task
    |> Task.changeset(task_params)
    |> repo.insert_or_update()
  end

  def store_workflow(workflow_params, workflow, repo \\ Repo) do
    workflow
    |> Workflow.changeset(workflow_params)
    |> repo.insert_or_update()
  end

  defp store_execution(execution_params, execution \\ %Execution{}) do
    execution
    |> Execution.changeset(execution_params)
    |> Repo.insert_or_update()
  end

  def get_workflow_stats(workflow_id) do
    {:ok, result} =
      Multi.new()
      |> Multi.run(:task_errors, fn repo, _changes ->
        {:ok, get_task_error_count(workflow_id, repo)}
      end)
      |> Multi.run(:execution_time, fn repo, _changes ->
        {:ok, get_latest_execution_time(workflow_id, repo)}
      end)
      |> Multi.run(:total_executions, fn repo, _changes ->
        {:ok, get_total_executions(workflow_id, repo)}
      end)
      |> Multi.run(:active_triggers, fn repo, _changes ->
        {:ok, Triggers.get_active_count_workflow_scheduled_triggers(workflow_id)}
      end)
      |> Repo.transaction()

    result
  end

  def get_total_executions(workflow_id, repo \\ Repo) do
    query =
      from(e in Execution,
        where: e.workflow_id == ^workflow_id,
        select: count(e.id)
      )

    repo.one(query)
  end

  def get_latest_execution_time(workflow_id, repo \\ Repo) do
    query =
      from(e in Execution,
        where: e.workflow_id == ^workflow_id and e.status == "completed",
        order_by: [desc: e.inserted_at],
        limit: 1
      )

    case repo.one(query) do
      nil -> 0
      execution -> NaiveDateTime.diff(execution.updated_at, execution.inserted_at, :second)
    end
  end

  def get_task_error_count(workflow_id, repo \\ Repo) do
    from(o in "oban_jobs",
      where:
        o.state == "cancelled" and
          fragment("args ->> 'workflow_id'") == fragment("?::text", ^workflow_id) and
          o.attempt > 1 and
          fragment("args ->> 'task_id'") != "",
      join: t in Task,
      on: fragment("args ->> 'task_id'") == fragment("?::text", t.id),
      group_by: [t.name, fragment("args ->> 'workflow_id'")],
      order_by: [desc: count(t.name)],
      limit: 3,
      select: %{
        task_name: t.name,
        error_count: count(t.name)
      }
    )
    |> repo.all()
    |> Enum.reject(fn x -> x.error_count == 0 end)
  end

  def generate_magic_form_code(user_request, magic_form, opts) do
    workflow = get_workflow_by_id(magic_form.workflow_id)

    params = %{
      "form_definition" => workflow.inputs_definition,
      "user_request" => user_request,
      "previous_form" => magic_form.html
    }

    execute_workflow(@magic_forms_generator_workflow_id, params, opts)
  end

  def duplicate_workflow(company_id, workflow_id) do
    result =
      Multi.new()
      |> Multi.run(:reference_workflow, fn repo, _ ->
        {:ok, get_workflow_by_id(workflow_id, repo)}
      end)
      |> Multi.run(:reference_tasks, fn repo, _ ->
        query =
          from(t in Task,
            where: t.workflow_id == ^workflow_id
          )

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:workflow, fn repo,
                                 %{
                                   reference_workflow: reference_workflow
                                 } ->
        data =
          reference_workflow
          |> Map.drop([
            :id,
            :__struct__,
            :__meta__,
            :inserted_at,
            :updated_at,
            :template_reference_for_id
          ])
          |> Map.merge(%{
            name: "Copy of #{reference_workflow.name}",
            description: reference_workflow.description,
            company_id: company_id
          })

        store_workflow(data, %Workflow{}, repo)
      end)
      |> Multi.run(:tasks, fn repo, %{workflow: workflow, reference_tasks: reference_tasks} ->
        tasks =
          Enum.map(reference_tasks, fn reference_task ->
            now = NaiveDateTime.utc_now(:second)

            reference_task
            |> Map.drop([
              :id,
              :__struct__,
              :__meta__
            ])
            |> Map.merge(%{
              id: Ecto.UUID.generate(),
              workflow_id: workflow.id,
              is_template_reference: false,
              template_reference_for_id: reference_task.id,
              inserted_at: now,
              updated_at: now
            })
          end)

        case repo.insert_all(Task, tasks, returning: true) do
          {count, _} when count > 0 -> {:ok, tasks}
          _ -> {:error, "Failed to duplicate tasks"}
        end
      end)
      |> Multi.run(:updated_workflow, fn repo, %{workflow: workflow, tasks: tasks} ->
        updated_graph = GraphUtils.remap_graph_tasks(workflow.graph, tasks)

        store_workflow(%{graph: updated_graph}, workflow, repo)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{workflow: workflow}} ->
        {:ok, workflow}

      {:error, error_msg} ->
        Logger.error("Error occurred: #{inspect(error_msg)}")

        {:error, "There was an error creating the workflow."}
    end
  end

  @spec charge_for_task_run(any(), %{:task_name => any(), :workflow_name => any(), optional(any()) => any()}) ::
          {:ok, pid()}
  def charge_for_task_run(
        company_id,
        %{task_type: "model", provider_slug: "plomb", task_name: task_name, workflow_name: workflow_name} = metadata
      ) do
    transaction_description = "PlombAI - #{task_name} - #{workflow_name}"

    Elixir.Task.start(fn ->
      Payments.remove_credits(:credits, company_id, 2, "USAGE", transaction_description, metadata)
    end)
  end

  def charge_for_task_run(
        company_id,
        %{task_name: task_name, workflow_name: workflow_name} = metadata
      ) do
    transaction_description = "#{task_name} - #{workflow_name}"

    Elixir.Task.start(fn ->
      Payments.remove_credits(:credits, company_id, 1, "USAGE", transaction_description, metadata)
    end)
  end

  def verify_credits_balance(company_id, %{"tasks" => tasks} = _workflow_graph) do
    credits_required = length(tasks)

    case Payments.has_enough_credits?(:credits, company_id, credits_required) do
      true -> :ok
      false -> {:error, :not_enough_credits}
    end
  end
end
