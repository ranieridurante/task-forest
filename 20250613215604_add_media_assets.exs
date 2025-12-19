defmodule TaskForest.Repo.Migrations.AddMediaAssets do
  use Ecto.Migration

  def up do
    create table(:media_assets) do
      add :company_id, :uuid
      add :workflow_id, :uuid
      add :execution_id, :uuid

      add :original_filename, :string
      add :content_type, :string
      add :byte_size, :integer
      add :storage_key, :string

      add :plomb_location_path, :string

      add :created_by_id, :uuid
      add :created_by_type, :string

      timestamps()
    end
  end

  def down do
    drop table(:media_assets)
  end
end
