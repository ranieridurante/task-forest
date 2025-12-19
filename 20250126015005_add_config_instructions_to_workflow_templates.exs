defmodule TaskForest.Repo.Migrations.AddConfigInstructionsToWorkflowTemplates do
  use Ecto.Migration

  def up do
    alter table(:workflow_templates) do
      add :markdown_instructions, :text
    end
  end

  def down do
    alter table(:workflow_templates) do
      remove :markdown_instructions
    end
  end
end
