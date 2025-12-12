defmodule TaskForest.Files.MediaAsset do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  schema "media_assets" do
    field :company_id, :binary_id
    field :workflow_id, :binary_id
    field :execution_id, :binary_id

    field :original_filename, :string
    field :content_type, :string
    field :byte_size, :integer
    field :storage_key, :string

    field :plomb_location_path, :string

    field :created_by_id, :binary_id
    field :created_by_type, :string

    timestamps()
  end

  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :company_id,
      :workflow_id,
      :execution_id,
      :original_filename,
      :content_type,
      :byte_size,
      :storage_key,
      :plomb_location_path,
      :created_by_id,
      :created_by_type,
      :updated_at,
      :inserted_at
    ])
    |> validate_required([
      :company_id,
      :workflow_id,
      :execution_id,
      :storage_key,
      :created_by_id,
      :created_by_type
    ])
  end
end
