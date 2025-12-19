defmodule TaskForest.Repo.Migrations.AddRolesUserCompanies do
  use Ecto.Migration

  def up do
    alter table(:user_companies) do
      add :roles, {:array, :string}, default: [], null: false
      add :is_admin, :boolean, default: false, null: false
    end
  end

  def down do
    alter table(:user_companies) do
      remove :roles
      remove :is_admin
    end
  end
end
