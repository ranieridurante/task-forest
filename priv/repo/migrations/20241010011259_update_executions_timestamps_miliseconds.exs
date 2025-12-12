defmodule TaskForest.Repo.Migrations.UpdateExecutionsTimestampsMiliseconds do
  use Ecto.Migration

  def up do
    alter table(:executions) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end
  end

  def down do
    alter table(:executions) do
      modify :inserted_at, :utc_datetime
      modify :updated_at, :utc_datetime
    end
  end
end
