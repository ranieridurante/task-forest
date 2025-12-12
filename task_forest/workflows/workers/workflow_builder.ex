defmodule TaskForest.Workflows.Workers.WorkflowBuilder do
  use Oban.Pro.Workers.Workflow

  require Logger

  alias TaskForest.Utils
  alias TaskForest.Workflows
  alias TaskForest.Workflows.GraphUtils
  alias TaskForest.Workflows.Workers.InitWorkflowWorker
  alias TaskForest.Workflows.Workers.IteratorWorker
  alias TaskForest.Workflows.Workers.ConvergerWorker
  alias TaskForest.Workflows.Workers.FinishWorkflowWorker
  alias TaskForest.Workflows.Workers.TaskWorker
  alias TaskForest.Workflows.Workers.WorkerUtils

  @impl true
  def process(%{meta: _meta}) do
    :ok
  end

  def insert_workflow(
        workflow_id,
        inputs_hash,
        %{"execution_id" => execution_id} = inputs,
        raw_graph,
        company_config,
        workflow_opts \\ %{}
      ) do
    job_opts = [
      priority: company_config["execution_priority"]
    ]

    last_tasks = GraphUtils.get_end_nodes(raw_graph)

    Workflow.new()
    |> Workflow.add(
      "workflow_inputs",
      InitWorkflowWorker.new(
        %{
          workflow_inputs: inputs,
          workflow_id: workflow_id,
          inputs_hash: inputs_hash,
          execution_id: execution_id
        },
        job_opts
      )
    )
    |> add_start_workers(
      raw_graph,
      %{
        execution_id: execution_id,
        workflow_opts: workflow_opts,
        workflow_id: workflow_id
      },
      job_opts
    )
    |> Oban.insert_all()
  end

  def add_start_workers(oban_workflow, raw_graph, worker_params, job_opts) do
    graph = GraphUtils.load_graph(raw_graph)

    start_tasks = GraphUtils.get_start_nodes(graph)

    max_concurrency_by_task = Workflows.get_max_concurrency_by_task_id_list(start_tasks)

    last_tasks = GraphUtils.get_end_nodes(raw_graph)

    Enum.reduce(start_tasks, oban_workflow, fn node_id, acc_oban_workflow ->
      worker_deps = ["workflow_inputs"]

      worker_params = Map.put(worker_params, "task_id", node_id)

      updated_acc_oban_workflow =
        WorkerUtils.add_task_to_workflow(
          acc_oban_workflow,
          node_id,
          worker_params,
          worker_deps,
          job_opts,
          max_concurrency_by_task,
          graph
        )

      if WorkerUtils.are_next_tasks_the_last?(start_tasks, last_tasks) and
           not WorkerUtils.is_worker_scheduled_within_execution?(
             worker_params[:workflow_id],
             "workflow_outputs",
             worker_params[:execution_id]
           ) do
        Workflow.add(
          updated_acc_oban_workflow,
          "workflow_outputs",
          FinishWorkflowWorker.new(
            worker_params,
            job_opts
          ),
          deps: last_tasks
        )
      else
        updated_acc_oban_workflow
      end
    end)
  end
end
