defmodule TaskForest.Payments.BillingProduct do
  use TaskForest.SchemaTemplate

  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :description,
             :grants,
             :provider,
             :provider_id,
             :provider_metadata,
             :product_id,
             :active
           ]}

  schema "billing_products" do
    field :name, :string
    field :description, :string
    field :grants, :map
    field :provider, :string
    field :provider_id, :string
    field :provider_metadata, :map
    field :product_id, :string
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(billing_product, attrs) do
    billing_product
    |> cast(attrs, [
      :name,
      :description,
      :grants,
      :provider,
      :provider_id,
      :provider_metadata,
      :product_id,
      :active
    ])
    |> validate_required([
      :name,
      :description,
      :grants,
      :provider,
      :provider_id,
      :provider_metadata
    ])
    |> unique_constraint([:provider_id, :provider], name: :unique_provider_id_provider)
  end
end
