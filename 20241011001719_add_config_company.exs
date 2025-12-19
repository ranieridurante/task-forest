defmodule TaskForest.Repo.Migrations.AddConfigCompany do
  use Ecto.Migration

  def up do
    alter table(:companies) do
      add :config, :map,
        default: %{
          execution_priority: 8
        }
    end
  end

  def down do
    alter table(:companies) do
      remove :config
    end
  end
end
