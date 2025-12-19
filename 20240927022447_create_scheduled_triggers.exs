defmodule TaskForest.Repo.Migrations.CreateScheduledTriggers do
  use Ecto.Migration

  def up do
    create table(:scheduled_triggers) do
      add :name, :string
      add :workflow_id, :string
      add :inputs, :map
      add :active, :boolean, default: true
      add :cron_expression, :string

      timestamps()
    end
  end

  def down do
    drop table(:scheduled_triggers)
  end
end
