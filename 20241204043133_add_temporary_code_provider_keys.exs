defmodule TaskForest.Repo.Migrations.AddTemporaryCodeProviderKeys do
  use Ecto.Migration

  def up do
    alter table(:provider_keys) do
      add :temporary_code, :text
    end

    create index(:provider_keys, [:temporary_code], using: :hash)
  end

  def down do
    alter table(:provider_keys) do
      remove :temporary_code
    end

    drop index(:provider_keys, [:temporary_code])
  end
end
