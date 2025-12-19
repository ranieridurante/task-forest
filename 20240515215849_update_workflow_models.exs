defmodule TaskForest.Repo.Migrations.UpdateWorkflowModels do
  use Ecto.Migration

  def up do
    alter table(:tasks) do
      remove :phase
      remove :pipe_to
    end

    alter table(:workflows) do
      add :graph, :jsonb
    end
  end

  def down do
    alter table(:tasks) do
      add :phase, :integer
      add :pipe_to, :string
    end

    alter table(:workflows) do
      remove :graph
    end
  end
end
