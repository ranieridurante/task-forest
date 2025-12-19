defmodule TaskForest.Repo.Migrations.AddProductUpdates do
  use Ecto.Migration

  def up do
    create table(:product_updates) do
      add :html_message, :text
      add :translations, :jsonb

      timestamps()
    end
  end

  def down do
    drop table(:product_updates)
  end
end
