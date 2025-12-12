defmodule TaskForest.Repo.Migrations.AddActiveCompanyToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :active_company_slug, :string
    end
  end

  def down do
    alter table(:users) do
      remove :active_company_slug
    end
  end
end
