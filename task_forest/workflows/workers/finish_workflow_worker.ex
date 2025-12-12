defmodule TaskForest.Workflows.Workers.FinishWorkflowWorker do
  use Oban.Pro.Workers.Workflow

  require Logger

  import IEx.Helpers, only: [pid: 1]

  alias TaskForest.Workflows
  alias TaskForest.Workflows.ExecutionUtils
  alias TaskForest.Workflows.Workers.WorkerUtils

  @impl true
  def process(
        %{
          args:
            %{
              "workflow_id" => workflow_id,
              "execution_id" => execution_id
            } = args
        } = job
      ) do
    plomb_workflow = Workflows.get_workflow_by_id(workflow_id)

    if WorkerUtils.have_previous_tasks_executed?(job, plomb_workflow.graph) do
      Logger.debug("Executing workflow_id=#{workflow_id} for execution_id=#{execution_id}")

      finish_workflow(job)
    else
      Logger.info("Waiting for previous tasks to execute workflow_id=#{workflow_id}. Snoozing for 60s")

      {:snooze, 60}
    end
  end

  def finish_workflow(
        %{
          meta: %{"name" => "workflow_outputs"},
          args:
            %{
              "workflow_id" => workflow_id,
              "execution_id" => execution_id
            } = args
        } = job
      ) do
    Logger.debug("Finishing workflow_id=#{workflow_id}")

    outputs = fetch_deps_outputs(job)

    Workflows.mark_execution_as_completed(execution_id, outputs)

    maybe_notify_workflow_completion(
      get_in(args, ["workflow_opts", "notify_to"]),
      workflow_id,
      execution_id,
      outputs
    )

    :ok
  end

  defp maybe_notify_workflow_completion(nil, _workflow_id, _execution_id, _outputs), do: :ok

  defp maybe_notify_workflow_completion(notify_to_pid, workflow_id, execution_id, outputs) do
    workflow = Workflows.get_workflow_by_id(workflow_id)

    {final_outputs, _intermediate_outputs} =
      ExecutionUtils.parse_outputs(
        outputs,
        workflow.outputs_definition,
        workflow.inputs_definition
      )

    send(
      pid(notify_to_pid),
      {:workflow_completed,
       %{
         execution_id: execution_id,
         outputs: final_outputs
       }}
    )
  end

  defp fetch_deps_outputs(job) do
    job
    |> Workflow.all_jobs(only_deps: true)
    |> then(fn jobs ->
      names = Enum.map(jobs, & &1.meta["name"])
      outputs = Enum.map(jobs, &fetch_recorded/1)

      Enum.zip(names, outputs)
    end)
    |> merge_partial_outputs()
  end

  defp merge_partial_outputs(name_with_outputs) do
    Enum.reduce(name_with_outputs, %{}, fn
      {task_name, {:ok, task_outputs}}, acc ->
        merge_single_task_outputs(task_name, task_outputs, acc)

      {_task_name, {:error, _}}, acc ->
        acc
    end)
  end

  defp merge_single_task_outputs(task_name, task_outputs, acc) do
    if String.contains?(task_name, "iter") do
      iterator_id = String.split(task_name, "_iter_") |> List.last()

      task_outputs
      |> Enum.map(fn {key, value} -> {"#{key}_iter_#{iterator_id}", value} end)
      |> then(fn outputs ->
        outputs = Map.new(outputs)

        Map.merge(acc, outputs, &WorkerUtils.merge_single_duplicate_task_outputs/3)
      end)
    else
      task_outputs = Map.new(task_outputs)

      Map.merge(acc, task_outputs, &WorkerUtils.merge_single_duplicate_task_outputs/3)
    end
  end
end
