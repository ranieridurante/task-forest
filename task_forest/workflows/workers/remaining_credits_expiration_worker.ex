defmodule TaskForest.Workflows.Workers.RemainingCreditsExpirationWorker do
  use Oban.Pro.Worker, queue: :credits, max_attempts: 3

  require Logger

  alias TaskForest.Payments
  alias TaskForest.Workflows.Workers.RemainingCreditsExpirationWorker

  @impl true
  def perform(%Oban.Job{args: %{"company_id" => company_id, "credits_transaction_id" => credits_transaction_id}}) do
    Logger.info("Starting credits expiration for company=#{company_id} from transaction=#{credits_transaction_id}")

    credit_transaction = Payments.get_credit_transaction(credits_transaction_id)

    current_balance = Payments.get_balance(:credits, company_id)

    remaining_credits =
      calculate_remaining_credits(
        credit_transaction,
        current_balance
      )

    if Decimal.positive?(remaining_credits) do
      Payments.remove_credits(
        :credits,
        company_id,
        remaining_credits,
        "EXPIRATION",
        "Expiration - #{credit_transaction.description}",
        %{
          "expired_transaction_id" => credit_transaction.id,
          "expiration_date" => DateTime.utc_now() |> DateTime.to_iso8601()
        }
      )
    end

    Logger.info(
      "Expired #{inspect(remaining_credits)} credits for company=#{company_id} from transaction=#{credits_transaction_id}"
    )

    :ok
  end

  defp calculate_remaining_credits(expired_credit_transaction, current_balance) do
    additions_amount =
      expired_credit_transaction
      |> Payments.get_credit_transaction_additions_since()
      |> Enum.reduce(Decimal.new(0), fn tx, acc ->
        Decimal.add(acc, tx.amount)
      end)

    balance_with_additions = Decimal.add(expired_credit_transaction.amount, additions_amount)

    credits_spent = Decimal.sub(balance_with_additions, current_balance)

    expired_credit_transaction.amount - credits_spent
  end
end
