defmodule TaskForest.Repo.Migrations.AddInputsOutputsDefToWorkflow do
  use Ecto.Migration

  def change do
    alter table(:workflows) do
      add :inputs_definition, :jsonb
      add :outputs_definition, :jsonb
    end
  end
end
