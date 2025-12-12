defmodule TaskForest.Accounts.Company do
  use TaskForest.SchemaTemplate

  import Ecto.Changeset

  alias TaskForest.Accounts.UserCompany

  @type company_config :: %{
          # Oban job priority, from 0 (higher) to 9
          execution_priority: non_neg_integer()
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :slug,
             :website,
             :config,
             :billing_plan
           ]}

  schema "companies" do
    field :name, :string
    field :slug, :string
    field :website, :string

    field :config, :map,
      default: %{
        execution_priority: 8,
        grants: %{
          roles: "admin",
          seats: 1,
          credits: 0,
          plombai: 0,
          support: "basic",
          workflows: 3,
          api_access: "none",
          magic_forms: 0,
          active_triggers: 0,
          data_retention_days: 7,
          execution_concurrency: 1
        }
      }

    field :billing_plan, :map

    field :auth_token, :string

    has_many :user_companies, UserCompany
    has_many :users, through: [:user_companies, :user]

    timestamps()
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :slug, :website, :updated_at, :inserted_at, :config, :billing_plan, :auth_token])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
