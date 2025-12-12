defmodule TaskForest.Accounts.UserCompany do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Accounts.Company
  alias TaskForest.Accounts.User

  schema "user_companies" do
    field :company_id, Ecto.UUID
    field :user_id, Ecto.UUID

    field :roles, {:array, :string}, default: []
    field :is_admin, :boolean, default: false

    has_one :company, Company, foreign_key: :id
    has_one :user, User, foreign_key: :id

    timestamps()
  end

  @doc false
  def changeset(user_company, attrs) do
    user_company
    |> cast(attrs, [:user_id, :company_id, :inserted_at, :updated_at, :roles, :is_admin])
    |> validate_required([:user_id, :company_id])
  end
end
