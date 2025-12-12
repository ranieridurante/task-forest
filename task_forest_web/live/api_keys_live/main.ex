defmodule TaskForestWeb.APIKeysLive.Main do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, %{assigns: %{active_company: active_company} = assigns} = socket) do
    company_auth_token =
      with company_auth_token <- Accounts.retrieve_company_auth_token(active_company.slug),
           false <- is_nil(company_auth_token) do
        company_auth_token
      else
        _ -> "AUTH_TOKEN"
      end

    routes =
      [
        %{href: "/home", label: "Home", icon: "mingcute:home-7-fill"},
        %{
          href: "/api-keys",
          label: "API Keys",
          icon: "material-symbols:key",
          active: true
        }
      ]

    {:noreply, assign(socket, page_title: "API Keys", company_auth_token: company_auth_token, routes: routes)}
  end

  @impl true
  def handle_event("react.generate_auth_token", _params, %{assigns: %{active_company: active_company}} = socket) do
    new_token = Accounts.generate_auth_token() |> Accounts.store_auth_token(active_company.slug)

    socket =
      socket
      |> assign(:company_auth_token, new_token)
      |> push_event("server.update_company_auth_token", %{
        company_auth_token: new_token
      })

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
      |> push_navigate(to: "/api-keys", replace: true)

    {:noreply, socket}
  end
end
