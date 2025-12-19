defmodule TaskForest.Repo.Migrations.AddProvidersAndProviderKeys do
  use Ecto.Migration

  def change do
    create table(:providers) do
      add :name, :string
      add :slug, :string
      add :keys, :map
      add :instructions, :text
      add :logo, :string
      add :website, :string

      timestamps()
    end

    create table(:provider_keys) do
      add :provider_id, :uuid
      add :keys, :map
      add :company_id, :uuid

      timestamps()
    end
  end
end
