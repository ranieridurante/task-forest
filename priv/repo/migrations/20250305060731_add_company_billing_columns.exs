defmodule TaskForest.Repo.Migrations.AddCompanyBillingColumns do
  use Ecto.Migration

  def up do
    alter table(:companies) do
      add :billing_plan, :jsonb
    end
  end

  def down do
    alter table(:companies) do
      remove :billing_plan
    end
  end
end
