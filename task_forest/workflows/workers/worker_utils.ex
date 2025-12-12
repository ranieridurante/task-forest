defmodule TaskForest.Workflows.Workers.WorkerUtils do
  use Oban.Pro.Workers.Workflow

  require Logger

  import Ecto.Query

  alias TaskForest.Repo
  alias TaskForest.Workflows
  alias TaskForest.Utils
  alias TaskForest.Workflows.FilterValidator
  alias TaskForest.Workflows.GraphUtils
  alias TaskForest.Workflows.Workers.ConvergerWorker
  alias TaskForest.Workflows.Workers.FinishWorkflowWorker
  alias TaskForest.Workflows.Workers.IteratorWorker
  alias TaskForest.Workflows.Workers.TaskWorker

  def add_finish_workflow_task(oban_workflow, job_args, job_opts, worker_deps) do
    oban_workflow =
      if not workflow_update_includes_worker?(oban_workflow, "workflow_outputs") and
           not is_worker_scheduled_within_execution?(
             job_args["workflow_id"],
             "workflow_outputs",
             job_args["execution_id"]
           ) do
        Workflow.add(
          oban_workflow,
          "workflow_outputs",
          FinishWorkflowWorker.new(job_args, job_opts),
          deps: worker_deps
        )
      else
        oban_workflow
      end

    oban_workflow
  end

  def get_oban_workflow_by_job(job) do
    {:ok, jobs} =
      Repo.transaction(fn ->
        job
        |> stream_all_workflow_jobs()
        |> Enum.to_list()
      end)

    append_workflow(jobs)
  end

  def get_worker_filter(nil, task_id), do: nil

  def get_worker_filter(filters, task_id) do
    Enum.find(filters, fn {filter_id, filter} ->
      filter["target"] == task_id
    end)
  end

  def validate_filter_condition(_worker_inputs, nil), do: false

  def validate_filter_condition(
        worker_inputs,
        {_filter_id,
         %{
           "variable_type" => "object",
           "variable_key" => variable_key,
           "property_path" => property_path,
           "property_path_type" => property_path_type
         } = filter}
      ) do
    property_path_keys = String.split(property_path, ".")

    value = get_in(worker_inputs[variable_key], property_path_keys)

    if value do
      updated_filter = Map.put(filter, "variable_type", property_path_type)

      FilterValidator.check_condition(updated_filter, value)
    else
      # TODO: Add log visible to user about target json missing value at path

      false
    end
  end

  def validate_filter_condition(worker_inputs, {_filter_id, %{"variable_key" => variable_key} = filter}) do
    FilterValidator.check_condition(filter, worker_inputs[variable_key])
  end

  def have_previous_tasks_executed?(%{meta: %{"name" => worker_name}} = job, raw_graph) do
    graph = GraphUtils.load_graph(raw_graph)

    task_id = job.args["task_id"] || worker_name

    previous_tasks =
      if worker_name == "workflow_outputs" do
        GraphUtils.get_end_nodes(raw_graph)
      else
        GraphUtils.get_previous_tasks(task_id, graph)
      end

    if previous_tasks == [] do
      true
    else
      previous_tasks =
        if String.contains?(worker_name, "_iter_") do
          iteration_key = String.split(task_id, "_iter_") |> List.last()

          previous_tasks
          |> Enum.map(fn task_id ->
            if Utils.is_uuid?(task_id) do
              "#{task_id}_iter_#{iteration_key}"
            else
              task_id
            end
          end)
        else
          previous_tasks
        end

      {:ok, executed_tasks} =
        Repo.transaction(fn ->
          job
          |> stream_all_workflow_jobs()
          |> Stream.filter(fn streamed_job ->
            streamed_job.state == "completed" and streamed_job.meta["name"] in previous_tasks
          end)
          |> Enum.to_list()
        end)

      length(executed_tasks) == length(previous_tasks)
    end
  end

  def add_task_to_workflow(oban_workflow, task_id, worker_params, worker_deps, job_opts, max_concurrency_by_task, graph) do
    iterable_key = worker_params[:iterable_key] || worker_params["iterable_key"]

    iteration_index =
      worker_params[String.to_atom("#{iterable_key}_index")] || worker_params["#{iterable_key}_index"]

    iterable_length = worker_params["#{iterable_key}_length"] || worker_params[String.to_atom("#{iterable_key}_length")]

    worker_name =
      if GraphUtils.is_node_iteration_instance?(graph, task_id, iterable_key) do
        "#{task_id}_iter_#{iterable_key}_#{iteration_index}"
      else
        task_id
      end

    workflow_id = worker_params[:workflow_id] || worker_params["workflow_id"]
    execution_id = worker_params[:execution_id] || worker_params["execution_id"]

    if not workflow_update_includes_worker?(oban_workflow, worker_name) and
         not is_worker_scheduled_within_execution?(workflow_id, worker_name, execution_id) do
      cond do
        String.starts_with?(task_id, "iter") ->
          Workflow.add(
            oban_workflow,
            worker_name,
            IteratorWorker.new(worker_params, job_opts),
            deps: worker_deps
          )

        String.starts_with?(task_id, "converger") ->
          cond do
            iterable_key == nil ->
              Workflow.add(
                oban_workflow,
                worker_name,
                ConvergerWorker.new(worker_params, job_opts),
                deps: worker_deps
              )

            iterable_key && iterable_length == iteration_index + 1 ->
              iteration_worker_deps =
                generate_iteration_worker_names(worker_params["spawner_worker_name"], iterable_length)

              Workflow.add(
                oban_workflow,
                worker_name,
                ConvergerWorker.new(worker_params, job_opts),
                deps: iteration_worker_deps
              )

            true ->
              oban_workflow
          end

        Utils.is_uuid?(task_id) ->
          worker_params = Map.put(worker_params, "task_id", task_id)

          max_concurrency = Map.get(max_concurrency_by_task, task_id)

          worker_queue =
            if max_concurrency do
              String.to_atom("max_concurrency_#{max_concurrency}")
            else
              :default
            end

          Workflow.add(
            oban_workflow,
            worker_name,
            TaskWorker.new(worker_params, job_opts ++ [queue: worker_queue]),
            deps: worker_deps
          )

        true ->
          Logger.warning("WorkerUtils.add_task_to_workflow - Skipping unidentified task_id=#{task_id}")

          oban_workflow
      end
    else
      Logger.warning("Skipping adding already scheduled worker #{worker_name}")

      oban_workflow
    end
  end

  def spawn_next_workflow_tasks(current_task_id, raw_graph, job) do
    oban_workflow = get_oban_workflow_by_job(job)

    worker_deps = [job.meta["name"]]

    graph = GraphUtils.load_graph(raw_graph)

    next_tasks = GraphUtils.get_next_tasks(current_task_id, graph)

    max_concurrency_by_task_id = Workflows.get_max_concurrency_by_task_id_list(next_tasks)

    job_opts = [
      priority: job.priority
    ]

    last_tasks = GraphUtils.get_end_nodes(raw_graph)

    oban_workflow =
      next_tasks
      |> Enum.reduce(oban_workflow, fn task_id, acc_oban_workflow ->
        task_args =
          Map.merge(job.args, %{
            "task_id" => task_id,
            "spawner_worker_name" => job.meta["name"]
          })

        add_task_to_workflow(
          acc_oban_workflow,
          task_id,
          task_args,
          worker_deps,
          job_opts,
          max_concurrency_by_task_id,
          graph
        )
      end)

    iterable_key = job.args[:iterable_key] || job.args["iterable_key"]
    iteration_index = job.args[String.to_atom("#{iterable_key}_index")] || job.args["#{iterable_key}_index"]
    iterable_length = job.args["#{iterable_key}_length"] || job.args[String.to_atom("#{iterable_key}_length")]

    oban_workflow =
      if are_next_tasks_the_last?(next_tasks, last_tasks) and
           not workflow_update_includes_worker?(oban_workflow, "workflow_outputs") and
           not is_worker_scheduled_within_execution?(
             job.args["workflow_id"],
             "workflow_outputs",
             job.args["execution_id"]
           ) and (iterable_key == nil || (iterable_key && iterable_length == iteration_index + 1)) do
        # TODO: add check to ensure this list includes all the previous tasks
        previous_oban_workflow_tasks = MapSet.to_list(oban_workflow.names)

        Workflow.add(
          oban_workflow,
          "workflow_outputs",
          FinishWorkflowWorker.new(
            Map.take(job.args, ["workflow_inputs", "workflow_id", "inputs_hash", "execution_id"]),
            job_opts
          ),
          deps: previous_oban_workflow_tasks
        )
      else
        oban_workflow
      end

    Oban.insert_all(oban_workflow)
  end

  def merge_single_duplicate_task_outputs("filtered_paths", left, right) when is_map(left) and is_map(right) do
    left_iter_keys =
      Map.keys(left)
      |> Enum.reject(&(&1 in ["approved", "skipped"]))

    right_iter_keys =
      Map.keys(right)
      |> Enum.reject(&(&1 in ["approved", "skipped"]))

    iter_keys = Enum.uniq(left_iter_keys ++ right_iter_keys)

    base_merged = %{
      "approved" => Enum.uniq(Map.get(left, "approved", []) ++ Map.get(right, "approved", [])),
      "skipped" => Enum.uniq(Map.get(left, "skipped", []) ++ Map.get(right, "skipped", []))
    }

    Enum.reduce(iter_keys, base_merged, fn key, acc ->
      left_iter = Map.get(left, key, %{"approved" => [], "skipped" => []})
      right_iter = Map.get(right, key, %{"approved" => [], "skipped" => []})

      Map.put(acc, key, %{
        "approved" => Enum.uniq(left_iter["approved"] ++ right_iter["approved"]),
        "skipped" => Enum.uniq(left_iter["skipped"] ++ right_iter["skipped"])
      })
    end)
  end

  def merge_single_duplicate_task_outputs(key, left, right) do
    right
  end

  def fetch_workflow_state_before_job(job) do
    {:ok, previous_jobs} =
      Repo.transaction(fn ->
        job
        |> stream_all_workflow_jobs()
        |> Stream.filter(fn streamed_job ->
          base_check =
            streamed_job.state == "completed" and
              NaiveDateTime.compare(streamed_job.inserted_at, job.inserted_at) in [:eq, :lt]

          iterable_key = job.args["iterable_key"]

          if iterable_key do
            index_key = "#{iterable_key}_index"

            base_check and
              (streamed_job.args[index_key] == nil or streamed_job.args[index_key] == job.args[index_key])
          else
            base_check
          end
        end)
        |> Enum.to_list()
      end)

    previous_jobs
    |> Enum.map(&fetch_recorded/1)
    |> merge_partial_outputs()
  end

  def are_next_tasks_the_last?(next_tasks, last_tasks) do
    next_tasks = MapSet.new(next_tasks)
    last_tasks = MapSet.new(last_tasks)

    not MapSet.disjoint?(next_tasks, last_tasks)
  end

  def workflow_update_includes_worker?(oban_workflow, worker_name) do
    workflow_workers = MapSet.to_list(oban_workflow.names)

    worker_name in workflow_workers
  end

  def is_worker_scheduled_within_execution?(workflow_id, worker_name, execution_id) do
    query =
      Oban.Job
      |> where(
        [job],
        # job.args.workflow_id (Plomb workflow) != job.meta.workflow_id (Oban workflow)
        fragment("? @> ?", job.args, ^%{workflow_id: workflow_id, execution_id: execution_id})
      )
      |> where([job], fragment("? @> ?", job.meta, ^%{name: worker_name}))

    Repo.exists?(query)
  end

  @doc """
  Replaces Oban.Workflow.stream_workflow_jobs/2.
  This function omits filtering the retrieved jobs by the deps listed.
  """
  def stream_all_workflow_jobs(job) do
    query =
      Oban.Job
      |> where([j], fragment("? @> ?", j.meta, ^%{workflow_id: job.meta["workflow_id"]}))
      |> order_by(asc: :id)

    Repo.stream(query)
  end

  def get_filtered_paths(nil = _worker_filter, raw_graph, task_id), do: nil

  def get_filtered_paths({filter_id, filter} = _worker_filter, raw_graph, task_id) do
    last_nodes = GraphUtils.get_end_nodes(raw_graph)

    graph = GraphUtils.load_graph(raw_graph)

    Enum.map(last_nodes, fn single_node_id ->
      Graph.Pathfinding.dijkstra(graph, task_id, single_node_id)
    end)
  end

  def skip_task?(task_id, worker_name, nil), do: false

  def skip_task?(task_id, worker_name, %{"approved" => approved_paths, "skipped" => skipped_paths} = filtered_paths) do
    {approved_paths, skipped_paths} =
      if String.contains?(worker_name, "_iter_") do
        iteration_key = String.split(worker_name, "_iter_") |> List.last()

        {filtered_paths[iteration_key]["approved"], filtered_paths[iteration_key]["skipped"]}
      else
        {approved_paths, skipped_paths}
      end

    approved_nodes =
      approved_paths
      |> flatten_filtered_paths()
      |> MapSet.new()

    skipped_nodes =
      skipped_paths
      |> flatten_filtered_paths()
      |> MapSet.new()

    final_skipped_nodes =
      skipped_nodes
      |> MapSet.difference(approved_nodes)
      |> MapSet.to_list()

    task_id in final_skipped_nodes
  end

  defp flatten_filtered_paths(filtered_paths) do
    Enum.reduce(filtered_paths, [], fn path, acc ->
      Enum.reduce(path, acc, fn node, inner_acc ->
        if node not in inner_acc do
          [node | inner_acc]
        else
          inner_acc
        end
      end)
    end)
  end

  defp merge_partial_outputs(partial_outputs) do
    Enum.reduce(partial_outputs, %{}, fn
      {:ok, task_outputs}, acc ->
        Map.merge(acc, task_outputs, &merge_single_duplicate_task_outputs/3)

      {:error, task_errors}, acc ->
        Logger.warning(
          "WorkerUtils.merge_partial_outputs/1 - Error fetching task outputs: #{inspect(task_errors)}. Skipping task outputs"
        )

        acc
    end)
  end

  defp generate_iteration_worker_names(worker_name, iterable_length) do
    reversed_name_chunks =
      worker_name
      |> String.split("_")
      |> Enum.reverse()

    Enum.map(0..(iterable_length - 1), fn index ->
      [index | tl(reversed_name_chunks)]
      |> Enum.reverse()
      |> Enum.join("_")
    end)
  end
end
