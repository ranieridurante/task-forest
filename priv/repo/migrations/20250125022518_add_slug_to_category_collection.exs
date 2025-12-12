defmodule TaskForest.Repo.Migrations.AddSlugToCategoryCollection do
  use Ecto.Migration

  def up do
    alter table(:categories) do
      add :slug, :string
    end

    create unique_index(:categories, [:slug])

    alter table(:workflow_template_collections) do
      add :slug, :string
    end

    create unique_index(:workflow_template_collections, [:slug])
  end
end
