defmodule TaskForest.Repo.Migrations.AddWorkflowTriggers do
  use Ecto.Migration

  defdelegate change, to: Oban.Pro.Migrations.Workflow
end
