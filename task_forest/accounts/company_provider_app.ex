defmodule TaskForest.Accounts.CompanyProviderApp do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Accounts.Company
  alias TaskForest.Accounts.ProviderKeys

  @derive {Jason.Encoder,
           only: [
             :id,
             :company_id,
             :provider_slug,
             :name,
             :config,
             :inserted_at,
             :updated_at
           ]}

  schema "company_provider_apps" do
    field :provider_slug, :string
    field :name, :string
    field :config, :binary

    belongs_to :company, Company
    has_many :provider_keys, ProviderKeys

    timestamps()
  end

  @doc false
  def changeset(company_provider_app, attrs) do
    company_provider_app
    |> cast(attrs, [:company_id, :provider_slug, :name, :config, :inserted_at, :updated_at])
    |> validate_required([:company_id, :provider_slug, :name, :config])
  end
end
