defmodule TaskForest.Repo.Migrations.AddActiveToProvider do
  use Ecto.Migration

  def up do
    alter table(:providers) do
      add :active, :boolean, default: true
    end
  end

  def down do
    alter table(:providers) do
      remove :active
    end
  end
end
