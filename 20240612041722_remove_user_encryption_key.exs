defmodule TaskForest.Repo.Migrations.RemoveUserEncryptionKey do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :encryption_key
    end
  end
end
