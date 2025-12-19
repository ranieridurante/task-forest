defmodule TaskForest.Repo.Migrations.ChangeBillingProductProviderMetadataType do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE billing_products ALTER COLUMN provider_metadata TYPE jsonb USING provider_metadata::jsonb"
  end

  def down do
    execute "ALTER TABLE billing_products ALTER COLUMN provider_metadata TYPE text USING provider_metadata::text"
  end
end
