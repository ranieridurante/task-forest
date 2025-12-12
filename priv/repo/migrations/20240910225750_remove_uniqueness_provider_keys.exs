defmodule TaskForest.Repo.Migrations.RemoveUniquenessProviderKeys do
  use Ecto.Migration

  def up do
    drop_if_exists unique_index(:provider_keys, [:company_id, :provider_id])
  end

  def down do
    create unique_index(:provider_keys, [:company_id, :provider_id])
  end
end
