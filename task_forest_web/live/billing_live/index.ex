defmodule TaskForestWeb.BillingLive.Index do
  use TaskForestWeb, :live_view

  require Logger

  alias TaskForest.Accounts
  alias TaskForest.Payments
  alias TaskForest.Payments.BillingProduct
  alias TaskForest.Utils
  alias TaskForestWeb.StripeHandler

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{active_company: active_company}} = socket) do
    credit_packages = StripeHandler.get_product_prices(:credits)

    credits_balance =
      :credits
      |> Payments.get_balance(active_company.id)
      |> Decimal.to_integer()
      |> Utils.add_number_commas()

    transactions = Payments.get_transactions(:credits, active_company.id)

    socket =
      socket
      |> assign(:page_title, "Billing")
      |> assign(:credit_packages, credit_packages)
      |> assign(:company_id, active_company.id)
      |> assign(:credits_balance, credits_balance)
      |> assign(:transactions, transactions)

    socket =
      if params["event_type"] == "success" and params["price_id"] != nil do
        socket
        |> put_flash(
          :info,
          "Your payment was successful! Your credits will be added to your account shortly."
        )
        |> redirect(to: "/billing")
      else
        socket
      end

    socket =
      if params["event_type"] == "cancel" do
        # TODO: send email after x hours to user with link to retry purchase
        socket
        |> redirect(to: "/billing")
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "react.buy_credits",
        %{"price_id" => price_id},
        %{assigns: %{active_company: active_company}} = socket
      ) do
    socket =
      case StripeHandler.create_checkout_session(:single_purchase, active_company.id, price_id) do
        {:ok, session_url} ->
          socket
          |> redirect(external: session_url)

        {:error, _reason} ->
          socket
          |> put_flash(
            :error,
            "Something went wrong when trying to buy credits. Please try again."
          )
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.select_plan",
        %{"plan_id" => plan_id, "billing_interval" => billing_interval},
        %{assigns: %{active_company: active_company}} = socket
      ) do
    # TODO: if company doesn't have active billing plan, trigger email flow with heavy discount for selected plan
    # https://docs.stripe.com/api/checkout/sessions/create#create_checkout_session-after_expiration

    # active_company.billing_plan != nil
    socket =
      with %BillingProduct{} = billing_product <- Payments.get_billing_product(plan_id, "stripe"),
           {:ok, price_id} <- get_plan_price_id(billing_product, plan_id, billing_interval),
           {:ok, checkout_session_url} <-
             StripeHandler.create_checkout_session(:subscription, active_company.id, price_id) do
        socket
        |> redirect(external: checkout_session_url)
      else
        _ ->
          socket
          |> put_flash(
            :error,
            "Something went wrong when trying to select a plan. Please try again."
          )
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.switch_organization",
        %{"new_active_company_slug" => new_active_company_slug} = _params,
        %{
          assigns: %{
            user_id: user_id,
            user_companies: user_companies
          }
        } = socket
      ) do
    Accounts.update_user_active_company(user_id, new_active_company_slug)

    active_company = Enum.find(user_companies, &(new_active_company_slug == &1.slug))

    socket =
      socket
      |> assign(:active_company, active_company)
      |> assign(:company, active_company)
      |> put_flash(:info, "Switched to #{active_company.name}")
      |> push_event("server.switch_organization", %{
        new_active_company: active_company
      })
      |> push_navigate(to: "/billing", replace: true)

    {:noreply, socket}
  end

  defp get_plan_price_id(billing_product, plan_id, billing_interval) do
    lookup_key = "#{String.upcase(plan_id)}_#{String.upcase(billing_interval)}"

    case billing_product.provider_metadata[lookup_key] do
      nil ->
        Logger.error("Price ID not found for plan #{inspect(lookup_key)}")

        {:error, "Price ID not found for plan"}

      price_id ->
        {:ok, price_id}
    end
  end
end
