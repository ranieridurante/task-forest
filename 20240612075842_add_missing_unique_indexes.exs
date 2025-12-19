defmodule TaskForest.Repo.Migrations.AddMissingUniqueIndexes do
  use Ecto.Migration

  def change do
    create unique_index(:user_companies, [:user_id, :company_id])
    create unique_index(:provider_keys, [:provider_id, :company_id])
    create unique_index(:companies, [:slug])
    create unique_index(:providers, [:slug])
    create unique_index(:workflows, [:slug, :company_id])
  end
end
