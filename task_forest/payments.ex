defmodule TaskForest.Payments do
  import Ecto.Query

  require Logger

  alias Ecto.Multi

  alias Oban.Pro.Plugins.DynamicCron

  alias TaskForest.Accounts
  alias TaskForest.Payments.BillingProduct
  alias TaskForest.Payments.CreditTransaction
  alias TaskForest.Repo
  alias TaskForest.Workflows.Workers.AddCreditsWorker
  alias TaskForest.Workflows.Workers.DeleteCronjobWorker
  alias TaskForest.Workflows.Workers.RemainingCreditsExpirationWorker

  @tx_type_options [
    "PURCHASE",
    "REFUND",
    "CHARGEBACK",
    "USAGE",
    "PROMOTION",
    "AFFILIATES",
    "SUPPORT",
    "EXPIRATION"
  ]

  @add_credit_tx_types ["PURCHASE", "AFFILIATES", "PROMOTION", "SUPPORT"]

  @plombai_credit_cost 2

  @plan_credits_expiration_days_seconds 30 * 24 * 60 * 60

  def get_billing_product(product_id, provider) do
    Repo.get_by(BillingProduct, product_id: product_id, provider: provider)
  end

  def get_balance(:credits, company_id, repo \\ Repo) do
    query =
      from(t in CreditTransaction,
        where: t.company_id == ^company_id,
        order_by: [desc: t.order],
        limit: 1
      )

    case repo.one(query) do
      nil -> 0.0
      transaction -> transaction.balance
    end
  end

  def get_credit_transaction(id) do
    Repo.get(CreditTransaction, id)
  end

  def get_credit_transaction_additions_since(credit_transaction) do
    query =
      from(t in CreditTransaction,
        where:
          t.transaction_type in ^@add_credit_tx_types and
            t.company_id == ^credit_transaction.company_id and
            t.order > ^credit_transaction.order,
        order_by: [asc: t.order]
      )

    Repo.all(query)
  end

  def has_enough_credits?(:credits, company_id, amount_required) do
    balance = get_balance(:credits, company_id)

    amount_required = Decimal.new(amount_required)

    Decimal.gt?(balance, amount_required) || Decimal.eq?(balance, amount_required)
  end

  def add_credits(:credits, company_id, amount, tx_type, reason, metadata \\ nil) do
    Multi.new()
    |> Multi.run(:balance, fn repo, _changes ->
      balance = get_balance(:credits, company_id, repo)

      {:ok, balance}
    end)
    |> Multi.run(:transaction, fn repo, %{balance: balance} ->
      new_balance =
        amount
        |> Decimal.new()
        |> Decimal.add(balance)

      %CreditTransaction{}
      |> CreditTransaction.changeset(%{
        company_id: company_id,
        balance: new_balance,
        previous_balance: balance,
        transaction_type: tx_type,
        reason: reason,
        metadata: metadata,
        amount: amount
      })
      |> repo.insert()
    end)
    |> Repo.transaction()
  end

  def remove_credits(:credits, company_id, amount, tx_type, reason, metadata \\ nil) do
    Multi.new()
    |> Multi.run(:balance, fn repo, _changes ->
      balance = get_balance(:credits, company_id, repo)

      {:ok, balance}
    end)
    |> Multi.run(:transaction, fn repo, %{balance: balance} ->
      new_balance = Decimal.sub(balance, Decimal.new(amount))

      %CreditTransaction{}
      |> CreditTransaction.changeset(%{
        company_id: company_id,
        balance: new_balance,
        previous_balance: balance,
        transaction_type: tx_type,
        reason: reason,
        metadata: metadata,
        amount: amount
      })
      |> repo.insert()
    end)
    |> Repo.transaction()
  end

  def find_stripe_transaction(:credits, company_id, charge_id) do
    query =
      from(t in CreditTransaction,
        where: t.company_id == ^company_id and t.metadata["charge_id"] == ^charge_id
      )

    Repo.one(query)
  end

  def get_transactions(:credits, company_id, limit \\ 50) do
    query =
      from(t in CreditTransaction,
        where: t.company_id == ^company_id,
        order_by: [desc: t.order],
        limit: ^limit
      )

    Repo.all(query)
  end

  def redeem_subscription(plan_id, billing_interval, company_id, tx_description, payment_metadata) do
    billing_product = get_billing_product(plan_id, "stripe")

    expiration_date = DateTime.utc_now() + @plan_credits_expiration_days_seconds

    credits_amount = billing_product.grants["credits"]

    {:ok, %{transaction: credits_transaction}} =
      add_credits(
        :credits,
        company_id,
        credits_amount,
        "PURCHASE",
        tx_description,
        payment_metadata
      )

    schedule_credits_expiration(company_id, credits_transaction.id, expiration_date)

    # TODO: temporarily add extra credits to use Plomb AI, until we track usage
    plombai_credits_amount = billing_product.grants["plombai"] * @plombai_credit_cost

    {:ok, %{transaction: plombai_credits_transaction}} =
      add_credits(
        :credits,
        company_id,
        plombai_credits_amount,
        "PURCHASE",
        "Plomb AI - #{tx_description}",
        payment_metadata
      )

    schedule_credits_expiration(company_id, plombai_credits_transaction.id, expiration_date)

    if billing_interval == "YEARLY" do
      schedule_yearly_plan_credits(company_id, billing_product, tx_description, payment_metadata)
    end

    update_company_billing_plan(company_id, billing_product, billing_interval)
  end

  def redeem_single_purchase("CREDITS_" <> amount = _price_lookup_key, company_id, tx_description, payment_metadata) do
    add_credits(
      :credits,
      company_id,
      amount,
      "PURCHASE",
      tx_description,
      payment_metadata
    )

    Logger.info("Added #{amount} credits of type credits to company #{company_id}")
  end

  def schedule_credits_expiration(company_id, credits_transaction_id, scheduled_at) do
    %{
      company_id: company_id,
      credits_transaction_id: credits_transaction_id
    }
    |> RemainingCreditsExpirationWorker.new(scheduled_at: scheduled_at)
    |> Oban.insert()
  end

  def update_company_billing_plan(company_id, billing_product, billing_interval) do
    company = Accounts.get_company(company_id)

    billing_plan = %{
      plan_id: billing_product.product_id,
      billing_interval: billing_interval,
      started_on: DateTime.utc_now(),
      payments_provider: billing_product.provider
    }

    # TODO: adapt when adding support for addons like extra seats
    company_config = Map.put(company.config, "grants", billing_product.grants)

    Accounts.update_company(company_id, %{billing_plan: billing_plan, config: company_config})
  end

  defp schedule_yearly_plan_credits(company_id, billing_product, tx_description, payment_metadata) do
    today = DateTime.utc_now()
    current_day = today.day

    # Schedule job at midnight on the same day every month
    cron_expression = "0 0 #{current_day} * *"

    credits_expiration_date = today + @plan_credits_expiration_days_seconds

    # Schedule deletion of yearly credits cron job 2 weeks before year ends
    plan_expiration_date = DateTime.utc_now() |> DateTime.add(31_536_000 - 1_209_600, :second)

    credits_amount = billing_product.grants["credits"]

    cron_name = "#{billing_product.product_id}_yearly_plan_credits_#{company_id}"

    DynamicCron.insert([
      {
        cron_expression,
        AddCreditsWorker,
        name: cron_name,
        queue: :credits,
        paused: false,
        args: %{
          "company_id" => company_id,
          "credits_amount" => credits_amount,
          "tx_description" => tx_description,
          "payment_metadata" => payment_metadata,
          "expiration_date" => credits_expiration_date
        }
      }
    ])

    %{
      cron_name: cron_name
    }
    |> DeleteCronjobWorker.new(scheduled_at: plan_expiration_date)
    |> Oban.insert()

    # TODO: temporarily add extra credits to use Plomb AI, until we track usage
    plombai_credits_amount = billing_product.grants["plombai"]

    plombai_cron_name = "#{billing_product.product_id}_yearly_plan_plombai_credits_#{company_id}"

    DynamicCron.insert([
      {
        cron_expression,
        AddCreditsWorker,
        name: plombai_cron_name,
        queue: :credits,
        paused: false,
        args: %{
          "company_id" => company_id,
          "credits_amount" => credits_amount,
          "tx_description" => "Plomb AI - #{tx_description}",
          "payment_metadata" => payment_metadata,
          "expiration_date" => credits_expiration_date
        }
      }
    ])

    %{
      cron_name: plombai_cron_name
    }
    |> DeleteCronjobWorker.new(scheduled_at: plan_expiration_date)
    |> Oban.insert()
  end
end
