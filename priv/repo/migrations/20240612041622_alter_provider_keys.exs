defmodule TaskForest.Repo.Migrations.AlterProviderKeys do
  use Ecto.Migration

  def change do
    alter table(:provider_keys) do
      remove :keys
      add :keys, :binary
    end
  end
end
