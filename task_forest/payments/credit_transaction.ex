defmodule TaskForest.Payments.CreditTransaction do
  use TaskForest.SchemaTemplate

  import Ecto.Changeset

  alias TaskForest.Accounts.Company

  @derive {Jason.Encoder,
           only: [
             :id,
             :company_id,
             :balance,
             :previous_balance,
             :amount,
             :transaction_type,
             :reason,
             :order
           ]}

  schema "credit_transactions" do
    field :balance, :decimal, default: 0.0
    field :previous_balance, :decimal, default: 0.0

    field :amount, :decimal, default: 0.0

    field :transaction_type, :string
    field :reason, :string

    # Order is used to keep transactions in order
    # It is set by a trigger in the database
    field :order, :integer
    field :metadata, :map

    belongs_to :company, Company

    timestamps()
  end

  def changeset(credit_transaction, attrs) do
    credit_transaction
    |> cast(attrs, [
      :company_id,
      :balance,
      :previous_balance,
      :transaction_type,
      :reason,
      :amount,
      :order,
      :metadata
    ])
    |> validate_required([
      :company_id,
      :balance,
      :previous_balance,
      :transaction_type,
      :reason,
      :amount
    ])
  end
end
