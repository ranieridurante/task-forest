defmodule TaskForest.Workflows.Workers.ConvergerWorker do
  use Oban.Pro.Workers.Workflow,
    recorded: [limit: 128_000],
    unique: [keys: [:execution_id, :name], fields: [:meta, :args]]

  require Logger

  alias TaskForest.Workflows
  alias TaskForest.Workflows.Workers.WorkerUtils

  @impl true
  def process(%{meta: %{"name" => converger_id}, args: %{"workflow_id" => workflow_id, "task_id" => task_id}} = job) do
    if WorkerUtils.have_previous_tasks_executed?(job, task_id) do
      workflow = Workflows.get_workflow_by_id(workflow_id)

      outputs = WorkerUtils.fetch_workflow_state_before_job(job)

      Logger.debug(
        "Executing converger_id=#{String.upcase(converger_id)} for workflow_id=#{outputs["workflow_id"]} and inputs_hash=#{outputs["inputs_hash"]}"
      )

      WorkerUtils.spawn_next_workflow_tasks(converger_id, workflow.graph, job)

      {:ok, outputs}
    else
      Logger.info(
        "Waiting for previous tasks to execute task_id=#{converger_id} for workflow_id=#{workflow_id}. Snoozing for 60s"
      )

      {:snooze, 60}
    end
  end

  # TODO: merge partial outputs adding iter suffix, see FinishWorkflow
end
