defmodule TaskForest.Repo.Migrations.ChangeTemporaryCodeToBinary do
  use Ecto.Migration

  def up do
    drop index(:provider_keys, [:temporary_code])

    alter table(:provider_keys) do
      remove :temporary_code
      add :temporary_code, :binary
      add :temporary_code_hash, :text
    end

    create index(:provider_keys, [:temporary_code_hash], using: :hash)
  end

  def down do
    drop index(:provider_keys, [:temporary_code_hash])

    alter table(:provider_keys) do
      remove :temporary_code_hash
      remove :temporary_code

      add :temporary_code, :text
    end

    create index(:provider_keys, [:temporary_code], using: :hash)
  end
end
