defmodule TaskForest.Repo.Migrations.AddFeaturedToProvidersTaskTemplates do
  use Ecto.Migration

  def change do
    alter table(:task_templates) do
      add :featured, :boolean, default: false, null: false
    end

    alter table(:providers) do
      add :featured, :boolean, default: false, null: false
    end
  end
end
