defmodule TaskForest.Workflows.Workers.IteratorWorker do
  use Oban.Pro.Workers.Workflow, recorded: [limit: 128_000]

  # TODO: add support for more than 1 iterator per workflow

  require Logger

  alias TaskForest.Repo
  alias TaskForest.Utils
  alias TaskForest.Workflows
  alias TaskForest.Workflows.GraphUtils
  alias TaskForest.Workflows.Workers.TaskWorker
  alias TaskForest.Workflows.Workers.ConvergerWorker
  alias TaskForest.Workflows.Workers.WorkerUtils

  @impl true
  def process(
        %{
          args: %{
            "task_id" => task_id,
            "workflow_id" => workflow_id,
            "execution_id" => execution_id,
            "workflow_opts" => workflow_opts
          }
        } =
          job
      ) do
    plomb_workflow = Workflows.get_workflow_by_id(workflow_id)

    if WorkerUtils.have_previous_tasks_executed?(job, plomb_workflow.graph) do
      Logger.debug("Executing iterator task_id=#{task_id} for workflow_id=#{workflow_id}")

      perform(job, plomb_workflow)
    else
      Logger.info(
        "Waiting for previous tasks to execute iterator task_id=#{task_id} for workflow_id=#{workflow_id}. Snoozing for 60s"
      )

      {:snooze, 60}
    end
  end

  defp perform(
         %{
           args: %{
             "task_id" => task_id,
             "workflow_id" => workflow_id,
             "execution_id" => execution_id,
             "workflow_opts" => workflow_opts
           }
         } = job,
         plomb_workflow
       ) do
    job_opts = [
      priority: job.priority
    ]

    graph = GraphUtils.load_graph(plomb_workflow.graph)

    partial_outputs = WorkerUtils.fetch_workflow_state_before_job(job)

    worker_filter = WorkerUtils.get_worker_filter(plomb_workflow.graph["filters"], task_id)

    is_filter_valid? = WorkerUtils.validate_filter_condition(partial_outputs, worker_filter)

    filtered_paths = WorkerUtils.get_filtered_paths(worker_filter, plomb_workflow.graph, task_id)

    default_filtered_paths = %{
      "approved" => [],
      "skipped" => []
    }

    current_filtered_paths = get_in(partial_outputs, ["filtered_paths"]) || default_filtered_paths

    updated_filtered_paths =
      cond do
        worker_filter == nil ->
          partial_outputs["filtered_paths"]

        worker_filter != nil and is_filter_valid? == false ->
          Map.put(current_filtered_paths, "skipped", current_filtered_paths["skipped"] ++ filtered_paths)

        true ->
          Map.put(current_filtered_paths, "approved", current_filtered_paths["approved"] ++ filtered_paths)
      end

    job_opts = [
      priority: job.priority
    ]

    oban_workflow = WorkerUtils.get_oban_workflow_by_job(job)

    if WorkerUtils.skip_task?(task_id, job.meta["meta"], updated_filtered_paths) do
      reason =
        if worker_filter != nil do
          {filter_id, filter_conditions} = worker_filter

          "Filter #{filter_id} - #{filter_conditions["variable_key"]}#{filter_conditions["property_path"]} #{filter_conditions["comparison_condition"]} #{filter_conditions["comparison_value"]} is FALSE"
        else
          partial_outputs["runtime_skip_task_reason"] ||
            "Task #{task_id} is skipped due to a filter condition"
        end

      Logger.info("Skipping task_id=#{task_id} during execution_id=#{execution_id}, reason: #{reason}")

      WorkerUtils.add_finish_workflow_task(
        oban_workflow,
        %{
          "workflow_id" => workflow_id,
          "execution_id" => execution_id,
          "workflow_opts" => workflow_opts
        },
        job_opts,
        [job.meta["name"]]
      )
      |> Oban.insert_all()

      skipped_task_output = %{
        "runtime_skip_task" => true,
        "runtime_skip_task_reason" => reason,
        "filtered_paths" => updated_filtered_paths
      }

      {:ok, skipped_task_output}
    else
      # ex. "iter_prompts"
      iterable_key = String.replace(task_id, "iter_", "")

      iterable_value = partial_outputs[iterable_key]

      worker_params = %{
        execution_id: execution_id,
        workflow_id: plomb_workflow.id,
        workflow_opts: workflow_opts
      }

      job
      |> WorkerUtils.get_oban_workflow_by_job()
      |> add_initial_tasks(
        iterable_key,
        iterable_value,
        graph,
        worker_params,
        job_opts
      )
      |> Oban.insert_all()

      {:ok,
       %{
         "filtered_paths" => updated_filtered_paths
       }}
    end
  end

  defp add_initial_tasks(
         oban_workflow,
         iterable_key,
         iterable_value,
         graph,
         worker_params,
         job_opts
       ) do
    iterator_id = "iter_#{iterable_key}"

    worker_deps = [iterator_id]

    initial_tasks = GraphUtils.get_next_tasks(iterator_id, graph)

    max_concurrency_by_task_id = Workflows.get_max_concurrency_by_task_id_list(initial_tasks)

    iterable_value
    |> Enum.with_index()
    |> Enum.reduce(oban_workflow, fn {value, index}, acc_oban_workflow ->
      Enum.reduce(initial_tasks, acc_oban_workflow, fn task_id, inner_acc_oban_workflow ->
        base_worker_params =
          worker_params
          |> Map.put(:iterable_key, iterable_key)
          |> Map.put(iterable_key |> Utils.singularize() |> String.to_atom(), value)
          |> Map.put(String.to_atom("#{iterable_key}_index"), index)
          |> Map.put(String.to_atom("#{iterable_key}_length"), length(iterable_value))

        WorkerUtils.add_task_to_workflow(
          inner_acc_oban_workflow,
          task_id,
          base_worker_params,
          worker_deps,
          job_opts,
          max_concurrency_by_task_id,
          graph
        )
      end)
    end)
  end
end
