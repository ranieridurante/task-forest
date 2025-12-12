defmodule TaskForest.Repo.Migrations.DropUniqueProviderKeysIndex do
  use Ecto.Migration

  def up do
    execute "DROP INDEX IF EXISTS provider_keys_provider_id_company_id_index"
  end

  def down do
    execute """
    CREATE UNIQUE INDEX provider_keys_provider_id_company_id_index
    ON provider_keys (provider_id, company_id)
    """
  end
end
