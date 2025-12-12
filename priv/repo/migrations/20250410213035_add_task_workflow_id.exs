defmodule TaskForest.Repo.Migrations.AddTaskWorkflowId do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""

    alter table(:tasks) do
      add :task_workflow_id, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end
  end

  def down do
    execute "DROP EXTENSION IF EXISTS \"uuid-ossp\""

    alter table(:tasks) do
      remove :task_workflow_id
    end
  end
end
