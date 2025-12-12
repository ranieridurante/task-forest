defmodule TaskForest.Repo.Migrations.AddTemplateLibraryTables do
  use Ecto.Migration

  def up do
    create table(:workflow_templates) do
      add :name, :string
      add :short_description, :text
      add :markdown_description, :text
      add :created_by_type, :string
      add :created_by_id, :string
      add :image_url, :string
      add :featured, :boolean
      add :published, :boolean

      timestamps()
    end

    create table(:categories) do
      add :name, :string
      add :icon, :string

      timestamps()
    end

    create table(:workflow_template_categories) do
      add :workflow_template_id,
          references(:workflow_templates,
            on_delete: :delete_all,
            name: :workflow_template_categories_workflow_template_id_fkey
          )

      add :category_id,
          references(:categories,
            on_delete: :nothing,
            name: :workflow_template_categories_category_id_fkey
          )

      timestamps()
    end

    create table(:workflow_template_collections) do
      add :title, :string
      add :short_description, :text
      add :image_url, :string
      add :markdown_description, :text

      timestamps()
    end

    create table(:workflow_template_collection_featured_providers) do
      add :workflow_template_collection_id,
          references(:workflow_template_collections,
            on_delete: :delete_all,
            name: :workflow_template_collection_featured_providers_collection_id_fkey
          )

      add :provider_id,
          references(:providers,
            on_delete: :nothing,
            name: :workflow_template_collection_featured_providers_provider_id_fkey
          )

      timestamps()
    end

    create table(:workflow_template_collection_workflow_templates) do
      add :workflow_template_collection_id,
          references(:workflow_template_collections,
            on_delete: :delete_all,
            name: :workflow_template_collection_workflow_templates_collection_id_fkey
          )

      add :workflow_template_id,
          references(:workflow_templates,
            on_delete: :nothing,
            name: :workflow_template_collection_workflow_templates_template_id_fkey
          )

      timestamps()
    end
  end

  def down do
    drop table(:workflow_template_collection_workflow_templates)
    drop table(:workflow_template_collection_featured_providers)
    drop table(:workflow_template_collections)
    drop table(:workflow_template_categories)
    drop table(:categories)
    drop table(:workflow_templates)
  end
end
