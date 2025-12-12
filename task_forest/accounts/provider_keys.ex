defmodule TaskForest.Accounts.ProviderKeys do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :alias,
             :inserted_at
           ]}

  schema "provider_keys" do
    field :keys, :string
    field :company_id, Ecto.UUID
    field :provider_id, Ecto.UUID
    field :alias, :string, default: "Default"

    field :temporary_code, :string
    field :temporary_code_hash, :string

    timestamps()
  end

  @doc false
  def changeset(provider_key, attrs) do
    provider_key
    |> cast(attrs, [
      :provider_id,
      :alias,
      :keys,
      :company_id,
      :inserted_at,
      :updated_at,
      :temporary_code,
      :temporary_code_hash
    ])
    |> validate_required([:provider_id, :company_id, :alias])
  end
end
