defmodule TaskForest.Workflows.Triggers do
  import Ecto.Query

  require Logger

  alias Oban.Pro.Plugins.DynamicCron

  alias TaskForest.Repo
  alias TaskForest.Workflows.ScheduledTrigger
  alias TaskForest.Workflows.Workers.ScheduledTriggerWorker

  def store_scheduled_trigger(params, scheduled_trigger) do
    scheduled_trigger
    |> ScheduledTrigger.changeset(params)
    |> Repo.insert_or_update()
  end

  def create_scheduled_trigger(params) do
    with {:ok, scheduled_trigger} <- store_scheduled_trigger(params, %ScheduledTrigger{}),
         {:ok, _} <- create_scheduled_trigger_cronjob(scheduled_trigger) do
      {:ok, scheduled_trigger}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Error creating scheduled trigger"}
    end
  end

  def get_scheduled_trigger(scheduled_trigger_id) do
    Repo.get(ScheduledTrigger, scheduled_trigger_id)
  end

  def get_workflow_scheduled_triggers(workflow_id) do
    Repo.all(from(s in ScheduledTrigger, where: s.workflow_id == ^workflow_id))
  end

  def get_active_count_workflow_scheduled_triggers(workflow_id) do
    Repo.one(
      from(s in ScheduledTrigger, where: s.workflow_id == ^workflow_id and s.active == true, select: count(s.id))
    )
  end

  def update_scheduled_trigger(params) do
    with scheduled_trigger <- get_scheduled_trigger(params["id"]),
         {:ok, updated_scheduled_trigger} <- store_scheduled_trigger(params, scheduled_trigger),
         {:ok, _} <- update_scheduled_trigger_cronjob(updated_scheduled_trigger) do
      {:ok, updated_scheduled_trigger}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Error updating scheduled trigger"}
    end
  end

  def delete_scheduled_trigger(scheduled_trigger_id) do
    case get_scheduled_trigger(scheduled_trigger_id) do
      nil ->
        {:error, "Scheduled trigger not found"}

      scheduled_trigger ->
        delete_scheduled_trigger_cronjob(scheduled_trigger)

        delete_stored_scheduled_trigger(scheduled_trigger)

        :ok
    end
  end

  def delete_stored_scheduled_trigger(scheduled_trigger) do
    Repo.delete(scheduled_trigger)
  end

  def delete_scheduled_trigger_cronjob(scheduled_trigger) do
    DynamicCron.delete("#{scheduled_trigger.id}_#{scheduled_trigger.workflow_id}")
  end

  def update_scheduled_trigger_cronjob(scheduled_trigger) do
    cron_name = "#{scheduled_trigger.id}_#{scheduled_trigger.workflow_id}"

    DynamicCron.update(
      cron_name,
      expression: scheduled_trigger.cron_expression,
      paused: not scheduled_trigger.active,
      args: %{
        "name" => cron_name,
        "workflow_id" => scheduled_trigger.workflow_id,
        "inputs" => scheduled_trigger.inputs
      }
    )
  end

  def create_scheduled_trigger_cronjob(scheduled_trigger) do
    cron_name = "#{scheduled_trigger.id}_#{scheduled_trigger.workflow_id}"

    DynamicCron.insert([
      {
        scheduled_trigger.cron_expression,
        ScheduledTriggerWorker,
        name: cron_name,
        queue: :scheduled_triggers,
        paused: false,
        args: %{
          "name" => cron_name,
          "workflow_id" => scheduled_trigger.workflow_id,
          "inputs" => scheduled_trigger.inputs
        }
      }
    ])
  end
end
