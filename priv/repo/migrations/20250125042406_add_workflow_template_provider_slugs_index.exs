defmodule TaskForest.Repo.Migrations.AddWorkflowTemplateProviderSlugsIndex do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    execute "CREATE INDEX workflow_templates_provider_slugs_trgm_idx ON workflow_templates USING gin ((provider_slugs) gin_trgm_ops)"
  end

  def down do
    execute "DROP INDEX IF EXISTS workflow_templates_provider_slugs_trgm_idx"
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
