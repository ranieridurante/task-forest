defmodule TaskForest.Repo.Migrations.AddWorkflowMemories do
  use Ecto.Migration

  def up do
    create table(:workflow_memories) do
      add :workflow_id, :string
      add :data, :map

      timestamps()
    end
  end

  def down do
    drop table(:workflow_memories)
  end
end
