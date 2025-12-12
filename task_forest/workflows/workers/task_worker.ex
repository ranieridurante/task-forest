defmodule TaskForest.Workflows.Workers.TaskWorker do
  use Oban.Pro.Workers.Workflow,
    recorded: [limit: 1_000_000]

  require Logger

  import IEx.Helpers, only: [pid: 1]

  alias TaskForest.Workflows
  alias TaskForest.Workflows.Workers.WorkerUtils

  @default_max_attempts 20

  @impl true
  def process(%{
        attempt: @default_max_attempts,
        args: %{
          "workflow_id" => workflow_id,
          "workflow_opts" => workflow_opts,
          "execution_id" => execution_id,
          "task_id" => task_id
        }
      }) do
    Logger.error("Max attempts reached for workflow #{workflow_id} execution #{execution_id}")

    outputs = %{
      error: "Max task attempts reached for task #{task_id}"
    }

    Workflows.mark_execution_as_cancelled(
      execution_id,
      outputs
    )

    Workflows.maybe_notify_workflow_cancellation(
      workflow_opts["notify_to"],
      execution_id,
      outputs
    )

    {:discard, "Max task attempts reached"}
  end

  def process(
        %{
          args:
            %{
              "task_id" => task_id,
              "execution_id" => execution_id
            } = args
        } = job
      ) do
    partial_outputs =
      job
      |> WorkerUtils.fetch_workflow_state_before_job()
      |> Map.merge(args, &WorkerUtils.merge_single_duplicate_task_outputs/3)

    case Workflows.get_task_context_by_id(task_id) do
      {:ok,
       %{
         workflow: workflow,
         task: _task,
         task_template: _task_template,
         provider_keys: _provider_keys,
         provider: _provider
       } = context} ->
        {:ok, execution} = Workflows.get_execution_by_id(execution_id)

        if WorkerUtils.have_previous_tasks_executed?(job, workflow.graph) do
          Logger.info("Executing task_id=#{task_id} for execution_id=#{execution.id}")

          perform_task(context, task_id, partial_outputs, execution, job)
        else
          Logger.info("Previous tasks not executed for task_id=#{task_id}. Snoozing for 60s")

          {:snooze, 60}
        end

      {:error, error_message} ->
        Logger.error("Error fetching task #{task_id} context: #{error_message}. Snoozing for 60s")

        {:snooze, 60}

      error ->
        Logger.error("Unexpected error fetching task #{task_id} context: #{inspect(error)}. Snoozing for 60s")

        {:snooze, 60}
    end
  end

  defp perform_task(
         %{workflow: workflow} = context,
         _task_id,
         _partial_outputs,
         %{status: "cancelled"} = execution,
         _job
       ) do
    Logger.info(
      "Execution #{execution.id} for workflow #{workflow.id} is cancelled. Discarding task.",
      task: context.task_template.name,
      task_name: context.task.name,
      provider: context.provider.name
    )

    {:discard, "Execution #{execution.id} for workflow #{workflow.id} is cancelled."}
  end

  defp perform_task(
         %{
           workflow: workflow,
           task: task,
           task_template: task_template,
           provider_keys: provider_keys,
           provider: provider,
           company: company
         } = _context,
         task_id,
         partial_outputs,
         execution,
         job
       ) do
    inputs =
      merge_inputs(task.inputs_definition, task_template.inputs_definition, partial_outputs)

    task_context = %{
      workflow_config: workflow.config,
      task: task,
      task_template: task_template,
      inputs: inputs,
      provider_keys: provider_keys,
      provider: provider,
      company_id: company.id,
      workflow_id: workflow.id,
      execution_id: execution.id
    }

    worker_filter = WorkerUtils.get_worker_filter(workflow.graph["filters"], task_id)

    is_filter_valid? = WorkerUtils.validate_filter_condition(partial_outputs, worker_filter)

    filtered_paths = WorkerUtils.get_filtered_paths(worker_filter, workflow.graph, task_id)

    default_filtered_paths = %{
      "approved" => [],
      "skipped" => []
    }

    current_filtered_paths = get_in(partial_outputs, ["filtered_paths"]) || default_filtered_paths

    iterable_key = job.args[:iterable_key] || job.args["iterable_key"]

    iteration_index =
      job.args[String.to_atom("#{iterable_key}_index")] || job.args["#{iterable_key}_index"]

    updated_filtered_paths =
      cond do
        worker_filter == nil ->
          partial_outputs["filtered_paths"]

        worker_filter != nil and is_filter_valid? == false ->
          if iterable_key != nil and iteration_index != nil do
            iteration_key = "#{iterable_key}_#{iteration_index}"

            put_in(
              current_filtered_paths,
              [iteration_key, "skipped"],
              (current_filtered_paths[iteration_key]["skipped"] || []) ++ filtered_paths
            )
          else
            Map.put(current_filtered_paths, "skipped", current_filtered_paths["skipped"] ++ filtered_paths)
          end

        true ->
          if iterable_key != nil and iteration_index != nil do
            iteration_key = "#{iterable_key}_#{iteration_index}"

            put_in(
              current_filtered_paths,
              [iteration_key, "approved"],
              (current_filtered_paths[iteration_key]["approved"] || []) ++ filtered_paths
            )
          else
            Map.put(current_filtered_paths, "approved", current_filtered_paths["approved"] ++ filtered_paths)
          end
      end

    if WorkerUtils.skip_task?(task_id, job.meta["name"], updated_filtered_paths) do
      reason =
        if worker_filter != nil do
          {filter_id, filter_conditions} = worker_filter

          "Filter #{filter_id} - #{filter_conditions["variable_key"]}#{filter_conditions["property_path"]} #{filter_conditions["comparison_condition"]} #{filter_conditions["comparison_value"]} is FALSE"
        else
          partial_outputs["runtime_skip_task_reason"] ||
            "Task #{task_id} is skipped due to a filter condition"
        end

      Logger.info("Skipping task_id=#{task_id} during execution_id=#{execution.id}, reason: #{reason}")

      WorkerUtils.spawn_next_workflow_tasks(task_id, workflow.graph, job)

      skipped_task_output = %{
        "runtime_skip_task" => true,
        "runtime_skip_task_reason" => reason,
        "filtered_paths" => updated_filtered_paths
      }

      {:ok, skipped_task_output}
    else
      if task_template.config["sleep_before"] do
        Logger.info("Sleeping before task #{task_id} for #{task_template.config["sleep_before"]} ms")

        :timer.sleep(task_template.config["sleep_before"])
      end

      results = Workflows.execute_task(task_context)

      if task_template.config["sleep_after"] do
        Logger.info("Sleeping after task #{task_id} for #{task_template.config["sleep_after"]} ms")

        :timer.sleep(task_template.config["sleep_after"])
      end

      results =
        case results do
          {:ok, task_outputs} ->
            credit_tx_metadata = %{
              task_id: task_id,
              provider_slug: task_template.provider_slug,
              task_type: task_template.config["type"],
              task_name: task.name,
              workflow_id: workflow.id,
              workflow_name: workflow.name,
              execution_id: execution.id
            }

            Workflows.charge_for_task_run(workflow.company_id, credit_tx_metadata)

            WorkerUtils.spawn_next_workflow_tasks(task_id, workflow.graph, job)

            Logger.info("Task #{task_id} executed successfully")

            {:ok,
             Map.merge(task_outputs, %{
               "filtered_paths" => updated_filtered_paths
             })}

          {:error, error_message} ->
            maybe_notify_error(job.args[:workflow_opts]["notify_to"], execution.id, %{
              error: error_message
            })

            Logger.warning("Task #{task_id} failed: #{error_message}")

            {:error, error_message}
        end

      results
    end
  end

  defp maybe_notify_error(nil, _execution_id, _outputs), do: :ok

  defp maybe_notify_error(notify_to_pid, execution_id, outputs) do
    send(
      pid(notify_to_pid),
      {:task_error,
       %{
         execution_id: execution_id,
         outputs: outputs
       }}
    )
  end

  defp merge_inputs(task_inputs_def, task_template_inputs_def, partial_outputs) do
    task_inputs =
      if task_inputs_def do
        Enum.reduce(task_inputs_def, %{}, fn {input_name, input_config}, acc ->
          if input_config["value"] != nil do
            Map.put(acc, input_name, input_config["value"])
          else
            acc
          end
        end)
      else
        %{}
      end

    task_template_inputs =
      if task_template_inputs_def do
        Enum.reduce(task_template_inputs_def, %{}, fn {input_name, input_config}, acc ->
          if input_config["default"] != nil do
            Map.put(acc, input_name, input_config["default"])
          else
            acc
          end
        end)
      else
        %{}
      end

    partial_outputs
    |> Map.merge(task_template_inputs)
    |> Map.merge(task_inputs)
  end
end
