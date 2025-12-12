defmodule TaskForest.Repo.Migrations.CreateBillingProducts do
  use Ecto.Migration

  def up do
    create table(:billing_products) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :grants, :jsonb, null: false

      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :provider_metadata, :string, null: false

      add :active, :boolean, default: true

      timestamps()
    end

    create unique_index(:billing_products, [:provider_id, :provider],
             name: :unique_provider_id_provider
           )
  end

  def down do
    drop_if_exists index(:billing_products, [:provider_id, :provider],
                     name: :unique_provider_id_provider
                   )

    drop table(:billing_products)
  end
end
