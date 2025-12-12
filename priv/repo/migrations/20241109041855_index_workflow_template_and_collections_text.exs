defmodule TaskForest.Repo.Migrations.IndexWorkflowTemplateAndCollectionsText do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    execute "CREATE INDEX workflow_templates_name_short_description_trgm_idx ON workflow_templates USING gin ((name || ' ' || short_description) gin_trgm_ops)"

    execute "CREATE INDEX workflow_template_collections_title_short_description_trgm_idx ON workflow_template_collections USING gin ((title || ' ' || short_description) gin_trgm_ops)"
  end

  def down do
    execute "DROP INDEX IF EXISTS workflow_templates_name_short_description_trgm_idx"
    execute "DROP INDEX IF EXISTS workflow_template_collections_title_short_description_trgm_idx"
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
