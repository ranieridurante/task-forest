defmodule TaskForest.Repo.Migrations.AddTemplateCreationFields do
  use Ecto.Migration

  def up do
    alter table(:tasks) do
      add :is_template_reference, :boolean, default: false
    end

    alter table(:workflow_templates) do
      add :workflow_id, references(:workflows, on_delete: :delete_all)
      add :tasks_updated_at, :naive_datetime
      add :provider_slugs, :text
      add :slug, :text
      add :usage_count, :integer, default: 0
    end

    create unique_index(:workflow_templates, [:slug])
  end

  def down do
    drop unique_index(:workflow_templates, [:slug])

    alter table(:workflow_templates) do
      remove :workflow_id
      remove :tasks_updated_at
      remove :provider_slugs
      remove :slug
      remove :usage_count
    end

    alter table(:tasks) do
      remove :is_template_reference
    end
  end
end
