defmodule TaskForest.Repo.Migrations.AddOauthTables do
  use Ecto.Migration

  def up do
    create table(:company_provider_apps) do
      add :company_id, references(:companies, on_delete: :delete_all)
      add :provider_slug, :string
      add :name, :string
      add :config, :binary

      timestamps()
    end

    alter table(:providers) do
      add :app_config_definition, :map
      add :app_setup_instructions, :text
    end

    alter table(:provider_keys) do
      add :company_provider_app_id, references(:company_provider_apps, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:provider_keys) do
      remove :company_provider_app_id
    end

    alter table(:providers) do
      remove :app_config_definition
    end

    drop table(:company_provider_apps)
  end
end
