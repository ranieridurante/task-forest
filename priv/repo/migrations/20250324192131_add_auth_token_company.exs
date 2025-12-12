defmodule TaskForest.Repo.Migrations.AddAuthTokenCompany do
  use Ecto.Migration

  def up do
    alter table(:companies) do
      add :auth_token, :binary
    end
  end

  def down do
    alter table(:companies) do
      remove :auth_token
    end
  end
end
