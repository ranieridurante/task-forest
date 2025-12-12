defmodule TaskForestWeb.StripeHandler do
  @behaviour Stripe.WebhookHandler

  require Logger

  alias TaskForest.Payments
  alias TaskForest.Utils

  @subscription_product_ids ["STARTER", "PROFESSIONAL", "ENTERPRISE"]
  @single_purchase_product_ids ["CREDITS"]

  def get_product_prices(:credits) do
    billing_product = Payments.get_billing_product("credits", "stripe")

    # TODO: Cache and expire every 24 hours
    case Stripe.Price.list(product: billing_product.provider_id) do
      {:ok, prices_list} ->
        Enum.map(prices_list.data, fn price_obj ->
          {amount, _credits_type} = parse_credits_package_id(price_obj.lookup_key)

          price =
            price_obj.unit_amount
            |> Decimal.new()
            |> Decimal.div(Decimal.new(100))

          %{
            price_id: price_obj.id,
            credits_amount: amount,
            price: price,
            currency: price_obj.currency,
            label: "#{Utils.add_number_commas(amount)} Credits",
            package_id: price_obj.lookup_key
          }
        end)
    end
  end

  def create_checkout_session(mode, company_id, price_id, discounts \\ [])

  def create_checkout_session(:subscription, company_id, price_id, discounts) do
    line_items = [
      %{
        price: price_id,
        quantity: 1
      }
    ]

    checkout_session =
      Stripe.Checkout.Session.create(
        allow_promotion_codes: true,
        # TODO: create success and cancel urls
        success_url: "http://localhost:4000/billing?event_type=success&prices_id=#{price_id}",
        cancel_url: "http://localhost:4000/billing?event_type=cancel&prices_id=#{price_id}",
        mode: "subscription",
        discounts: discounts,
        line_items: line_items,
        metadata: %{"company_id" => company_id},
        automatic_tax: %{
          enabled: true
        },
        tax_id_collection: %{
          enabled: true
        }
      )

    case checkout_session do
      {:ok, checkout_session} ->
        {:ok, checkout_session.url}

      {:error, error} ->
        Logger.error("Error creating checkout session: #{inspect(error)}")
        {:error, "Error creating checkout session"}
    end
  end

  def create_checkout_session(:single_purchase, company_id, price_id, discounts) do
    line_items = [
      %{
        price: price_id,
        quantity: 1
      }
    ]

    checkout_session =
      Stripe.Checkout.Session.create(
        allow_promotion_codes: true,
        customer_creation: "always",
        # TODO: create success and cancel urls
        success_url: "http://localhost:4000/billing?event_type=success&prices_id=#{price_id}",
        cancel_url: "http://localhost:4000/billing?event_type=cancel&prices_id=#{price_id}",
        mode: "payment",
        discounts: discounts,
        line_items: line_items,
        metadata: %{"company_id" => company_id},
        automatic_tax: %{
          enabled: true
        },
        tax_id_collection: %{
          enabled: true
        }
      )

    case checkout_session do
      {:ok, checkout_session} ->
        {:ok, checkout_session.url}

      {:error, error} ->
        Logger.error("Error creating checkout session: #{inspect(error)}")
        {:error, "Error creating checkout session"}
    end
  end

  @impl true
  def handle_event(%Stripe.Event{type: event_type, data: %{object: checkout_session}} = _event)
      when event_type in [
             "checkout.session.async_payment_succeeded",
             "checkout.session.completed"
           ] do
    company_id = checkout_session.metadata["company_id"]

    Logger.info("Processing Stripe checkout session #{checkout_session.id} for company #{company_id}")

    with {:ok, checkout_session} <-
           Stripe.Checkout.Session.retrieve(checkout_session.id, %{
             "expand" => ["line_items", "payment_intent"]
           }),
         true <- checkout_session.payment_status != "unpaid" do
      line_items = checkout_session.line_items.data

      Enum.each(line_items, fn line_item ->
        [product_id, product_type | _] = String.split(line_item.price.lookup_key, "_", parts: 2)

        payment_metadata = %{
          "checkout_session_id" => checkout_session.id,
          "line_item_id" => line_item.id,
          "customer_details" => checkout_session.customer_details,
          "customer_id" => checkout_session.payment_intent.customer,
          "charge_id" => checkout_session.payment_intent.latest_charge
        }

        cond do
          product_id in @subscription_product_ids ->
            Payments.redeem_subscription(product_id, product_type, company_id, line_item.description, payment_metadata)

          product_id in @single_purchase_product_ids ->
            Payments.redeem_single_purchase(
              line_item.price.lookup_key,
              company_id,
              line_item.description,
              payment_metadata
            )

          true ->
            Logger.error("Unknown product_id #{product_id} in checkout session #{checkout_session.id}")
        end
      end)

      :ok
    end
  end

  # TODO: check scheduled crons that reset and add credits on refunds and chargebacks
  # TODO: listen stripehandler on subscription cancel to change company.billing_plan

  @impl true
  def handle_event(%Stripe.Event{type: "charge.refunded", data: %{object: charge}} = _event) do
    Logger.info("Received charge.refunded Stripe event for charge #{charge.id}")

    checkout_sessions =
      Stripe.Checkout.Session.list(%{payment_intent: charge.payment_intent},
        expand: ["data.line_items"]
      )

    case checkout_sessions do
      {:ok, checkout_sessions_list} ->
        checkout_session = hd(checkout_sessions_list.data)

        company_id = checkout_session.metadata["company_id"]

        line_items = checkout_session.line_items.data

        Enum.each(line_items, fn line_item ->
          credits_package_id = line_item.price.lookup_key

          {amount, credits_type} = parse_credits_package_id(credits_package_id)

          transaction = Payments.find_stripe_transaction(credits_type, company_id, charge.id)

          if transaction do
            refund_metadata = %{
              "charge_id" => charge.id,
              "checkout_session_id" => checkout_session.id,
              "line_item_id" => line_item.id,
              "customer_details" => checkout_session.customer_details,
              "customer_id" => checkout_session.customer
            }

            Payments.remove_credits(
              credits_type,
              company_id,
              amount,
              "REFUND",
              "Refund for #{line_item.description}",
              refund_metadata
            )

            Logger.info(
              "Removed #{amount} credits of type #{credits_type} from company #{company_id} for charge #{charge.id} because of refund"
            )
          end
        end)

      {:error, error} ->
        Logger.error(
          "Error retrieving associated Stripe checkout session for charge #{charge.id} and payment intent #{charge.payment_intent}: #{inspect(error)}"
        )
    end

    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "charge.dispute.created", data: %{object: dispute}} = _event) do
    Logger.info("Received charge.dispute.created Stripe event for charge #{dispute.charge} and dispute #{dispute.id}")

    with {:ok, charge} <- Stripe.Charge.retrieve(dispute.charge),
         {:ok, checkout_sessions_list} <-
           Stripe.Checkout.Session.list(%{payment_intent: charge.payment_intent},
             expand: ["data.line_items"]
           ) do
      checkout_session = hd(checkout_sessions_list.data)

      company_id = checkout_session.metadata["company_id"]

      line_items = checkout_session.line_items.data

      Enum.each(line_items, fn line_item ->
        credits_package_id = line_item.price.lookup_key

        {amount, credits_type} = parse_credits_package_id(credits_package_id)

        transaction = Payments.find_stripe_transaction(credits_type, company_id, charge.id)

        if transaction do
          chargeback_metadata = %{
            "dispute_id" => dispute.id,
            "charge_id" => charge.id,
            "checkout_session_id" => checkout_session.id,
            "line_item_id" => line_item.id,
            "customer_details" => checkout_session.customer_details,
            "customer_id" => checkout_session.customer
          }

          Payments.remove_credits(
            credits_type,
            company_id,
            amount,
            "CHARGEBACK",
            "Chargeback for #{line_item.description}",
            chargeback_metadata
          )

          Logger.info(
            "Removed #{amount} credits of type #{credits_type} from company #{company_id} for charge #{charge.id} because of chargeback dispute_id=#{dispute.id}"
          )
        end
      end)
    else
      {:error, error} ->
        Logger.error(
          "Error retrieving data associated to Stripe dispute #{dispute.id} and charge #{dispute.charge}: #{inspect(error)}"
        )
    end

    :ok
  end

  # Return HTTP 200 for unhandled events
  @impl true
  def handle_event(_event), do: :ok

  defp parse_credits_package_id(package_id) do
    [amount, credits_type] = String.split(package_id, "_", parts: 2)

    {String.to_integer(amount), credits_type}
  end
end
