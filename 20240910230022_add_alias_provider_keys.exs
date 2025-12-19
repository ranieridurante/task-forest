defmodule TaskForest.Repo.Migrations.AddAliasProviderKeys do
  use Ecto.Migration

  def change do
    alter table(:provider_keys) do
      add :alias, :string
    end
  end
end
