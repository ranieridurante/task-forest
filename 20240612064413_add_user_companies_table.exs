defmodule TaskForest.Repo.Migrations.AddUserCompaniesTable do
  use Ecto.Migration

  def change do
    create table(:user_companies) do
      add :user_id, :uuid
      add :company_id, :uuid

      timestamps()
    end
  end
end
