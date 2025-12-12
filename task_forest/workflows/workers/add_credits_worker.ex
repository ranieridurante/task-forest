defmodule TaskForest.Workflows.Workers.AddCreditsWorker do
  use Oban.Pro.Worker, queue: :credits, max_attempts: 3

  require Logger

  alias TaskForest.Payments
  alias TaskForest.Payments.CreditTransaction

  @plan_credits_expiration_days_seconds 30 * 24 * 60 * 60

  @impl true
  def perform(%Oban.Job{
        args:
          %{
            "company_id" => company_id,
            "credits_amount" => credits_amount,
            "tx_description" => tx_description,
            "payment_metadata" => payment_metadata
          } = args
      }) do
    Logger.info("Starting scheduled credits addition for company=#{company_id} tx_description=#{tx_description}")

    {:ok, %{transaction: credits_transaction}} =
      Payments.add_credits(
        :credits,
        company_id,
        credits_amount,
        "PURCHASE",
        tx_description,
        payment_metadata
      )

    expiration_date = args["expiration_date"]

    if expiration_date do
      Payments.schedule_credits_expiration(company_id, credits_transaction.id, expiration_date)
    end

    Logger.info(
      "Added #{credits_amount} scheduled credits for company=#{company_id} with transaction_id=#{credits_transaction.id}"
    )

    :ok
  end
end
