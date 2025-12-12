defmodule TaskForestWeb.InitAssignsDefault do
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:user_id, nil)
      |> assign(:user_info, nil)
      |> assign(:active_company, nil)
      |> assign(:user_companies, nil)
      |> assign(:routes, nil)
      |> assign(:allow_org_switch, false)

    {:cont, socket}
  end
end

defmodule TaskForestWeb.InitAssignsAuth do
  import Phoenix.Component
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias TaskForest.Accounts

  def on_mount(
        :default,
        _params,
        %{
          "user_id" => user_id,
          "user_companies" => user_companies,
          "user_info" => user_info,
          "active_company" => session_active_company
        } = _session,
        socket
      ) do
    user = Accounts.get_user_by_id(user_id)

    active_company = Enum.find(user_companies, &(user.active_company_slug == &1.slug))

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:user_info, user_info)
      |> assign(:active_company, active_company || session_active_company)
      |> assign(:user_companies, user_companies)
      |> assign(:routes, nil)
      |> assign(:allow_org_switch, true)

    {:cont, socket}
  end

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:user_id, nil)
      |> assign(:user_info, nil)
      |> assign(:active_company, nil)
      |> assign(:user_companies, nil)
      |> assign(:routes, nil)
      |> assign(:allow_org_switch, false)
      |> put_flash(:error, "You must be logged in to access this page.")
      |> redirect(to: "/login")

    {:halt, socket}
  end
end
