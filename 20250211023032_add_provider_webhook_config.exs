defmodule TaskForest.Repo.Migrations.AddProviderWebhookConfig do
  use Ecto.Migration

  def up do
    alter table(:providers) do
      add :webhook_config, :jsonb
    end
  end

  def down do
    alter table(:providers) do
      remove :webhook_config
    end
  end
end
