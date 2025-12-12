defmodule TaskForest.Repo.Migrations.AddProductIdToBillingProducts do
  use Ecto.Migration

  def up do
    alter table(:billing_products) do
      add :product_id, :string
    end

    create unique_index(:billing_products, [:product_id])
  end

  def down do
    drop_if_exists index(:billing_products, [:product_id])

    alter table(:billing_products) do
      remove :product_id
    end
  end
end
