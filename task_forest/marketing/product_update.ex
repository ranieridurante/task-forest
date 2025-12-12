defmodule TaskForest.Marketing.ProductUpdate do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  schema "product_updates" do
    field :html_message, :string
    field :translations, :map

    timestamps()
  end

  @doc false
  def changeset(product_update, attrs) do
    product_update
    |> cast(attrs, [:html_message, :translations])
    |> validate_required([:html_message])
  end
end
