defmodule TaskForest.Repo.Migrations.ChangeWorkflowTemplateFeaturedProviderKey do
  use Ecto.Migration

  def up do
    alter table(:workflow_template_collection_featured_providers) do
      remove :provider_id
      add :provider_slug, :string, null: false
    end
  end

  def down do
    alter table(:workflow_template_collection_featured_providers) do
      remove :provider_slug
      add :provider_id, references(:providers, on_delete: :delete_all)
    end
  end
end
