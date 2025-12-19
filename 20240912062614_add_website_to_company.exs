defmodule TaskForest.Repo.Migrations.AddWebsiteToCompany do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :website, :string
    end
  end
end
