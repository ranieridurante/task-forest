defmodule TaskForest.Repo.Migrations.AddUserEncryptionKey do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :encryption_key, :string
    end
  end
end
