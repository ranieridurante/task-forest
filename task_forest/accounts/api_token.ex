defmodule TaskForest.Accounts.ApiToken do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  schema "api_tokens" do
    field :company_id, :string
    field :token, :string
    field :alias, :string

    timestamps()
  end

  @doc false
  def changeset(api_token, attrs) do
    api_token
    |> cast(attrs, [:company_id, :token, :alias, :updated_at, :inserted_at])
    |> validate_required([:company_id, :token, :alias])
    |> unique_constraint([:company_id, :alias])
  end
end
