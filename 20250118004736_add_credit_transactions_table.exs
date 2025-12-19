defmodule TaskForest.Repo.Migrations.AddCreditTransactionsTable do
  use Ecto.Migration

  def up do
    create table(:credit_transactions) do
      add :company_id, references(:companies, on_delete: :nothing)
      add :balance, :decimal, default: 0.0
      add :previous_balance, :decimal, default: 0.0
      add :transaction_type, :string
      add :reason, :string
      add :amount, :decimal
      add :order, :integer
      add :metadata, :jsonb

      timestamps()
    end

    execute """
    CREATE SEQUENCE credit_transactions_order_seq;
    """

    execute """
    CREATE OR REPLACE FUNCTION credit_transactions_order_trigger()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW."order" := nextval('credit_transactions_order_seq');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER set_credit_transactions_order
    BEFORE INSERT ON credit_transactions
    FOR EACH ROW
    EXECUTE FUNCTION credit_transactions_order_trigger();
    """
  end

  def down do
    drop table(:credit_transactions)

    execute """
    DROP TRIGGER IF EXISTS set_credit_transactions_order ON credit_transactions;
    """

    execute """
    DROP FUNCTION IF EXISTS credit_transactions_order_trigger();
    """

    execute """
    DROP SEQUENCE IF EXISTS credit_transactions_order_seq;
    """
  end
end
