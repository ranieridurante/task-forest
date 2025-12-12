defmodule TaskForest.Accounts.User do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Accounts.UserCompany

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :active_company_slug, :string

    has_many :user_companies, UserCompany
    has_many :companies, through: [:user_companies, :company]

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :active_company_slug,
      :inserted_at,
      :updated_at
    ])
    |> validate_required([:email])
    |> unique_constraint([:email])
  end
end
