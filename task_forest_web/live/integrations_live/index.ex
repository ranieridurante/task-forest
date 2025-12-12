defmodule TaskForestWeb.IntegrationsLive.Index do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Providers

  def mount(_params, _session, socket) do
    active_company = socket.assigns.active_company

    {:ok, providers_with_stored_keys} =
      Accounts.get_providers_with_keys_and_apps(active_company.id)

    socket =
      socket
      |> assign(:providers_with_stored_keys, providers_with_stored_keys)

    {:ok, socket}
  end

  def apply_action(
        %{assigns: %{active_company: active_company}} = socket,
        :index,
        _params
      ) do
    {:ok, providers_with_stored_keys} =
      Accounts.get_providers_with_keys_and_apps(active_company.id)

    socket
    |> assign(:providers_with_stored_keys, providers_with_stored_keys)
    |> push_event("server.update_connected_providers", %{
      connected_providers: providers_with_stored_keys
    })
  end

  def handle_event(
        "react.delete_provider_key",
        %{"key_id" => provider_key_id, "provider_id" => provider_id} = _params,
        socket
      ) do
    active_company = socket.assigns.active_company

    socket =
      with {:ok, _provider_key} <- Accounts.delete_provider_keys(provider_key_id),
           {:ok, updated_providers} <-
             Accounts.get_providers_with_keys_and_apps(active_company.id),
           provider_stored_keys <-
             Accounts.get_company_provider_keys(active_company.id, provider_id) do
        socket
        |> push_event("server.update_connected_providers", %{
          connected_providers: updated_providers
        })
        |> push_event("server.update_provider_stored_keys", %{
          provider_stored_keys: provider_stored_keys
        })
        |> put_flash(:info, "Successfully deleted provider key")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.add_provider_key",
        %{"provider_id" => provider_id, "keys" => _keys, "alias" => _alias} = params,
        socket
      ) do
    # Assigns current user company
    active_company = socket.assigns.active_company
    params = Map.put(params, "company_id", active_company.id)

    socket =
      with {:ok, _provider_key} <- Accounts.store_provider_keys(params),
           {:ok, updated_providers} <-
             Accounts.get_providers_with_keys_and_apps(active_company.id),
           provider_stored_keys <-
             Accounts.get_company_provider_keys(active_company.id, provider_id) do
        socket
        |> push_event("server.update_connected_providers", %{
          connected_providers: updated_providers
        })
        |> push_event("server.update_provider_stored_keys", %{
          provider_stored_keys: provider_stored_keys
        })
        |> put_flash(:info, "Successfully added provider key")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
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
      |> apply_action(:index, %{})
      |> push_event("server.switch_organization", %{
        new_active_company: active_company
      })

    {:noreply, socket}
  end

  def handle_event(
        "react.configure_new_app",
        %{"provider_id" => provider_id} = params,
        %{assigns: %{active_company: company}} = socket
      ) do
    params = Map.put(params, "company_id", company.id)

    socket =
      with {:ok, _company_provider_app} <- Accounts.store_company_provider_app(params),
           {:ok, updated_providers} <- Accounts.get_providers_with_keys_and_apps(company.id),
           provider_stored_keys <- Accounts.get_company_provider_keys(company.id, provider_id) do
        socket
        |> push_event("server.update_connected_providers", %{
          connected_providers: updated_providers
        })
        |> push_event("server.update_provider_stored_keys", %{
          provider_stored_keys: provider_stored_keys
        })
        |> put_flash(:info, "Successfully added app")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_app",
        %{"app_id" => app_id, "provider_id" => provider_id},
        %{assigns: %{active_company: active_company}} = socket
      ) do
    socket =
      with :ok <- Accounts.delete_company_provider_app(app_id),
           {:ok, updated_providers} <-
             Accounts.get_providers_with_keys_and_apps(active_company.id),
           provider_stored_keys <-
             Accounts.get_company_provider_keys(active_company.id, provider_id) do
        socket
        |> push_event("server.update_connected_providers", %{
          connected_providers: updated_providers
        })
        |> push_event("server.update_provider_stored_keys", %{
          provider_stored_keys: provider_stored_keys
        })
        |> put_flash(:info, "Successfully deleted app")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("react.add_account", %{"app_id" => app_id}, socket) do
    socket =
      case Providers.generate_oauth2_authorize_url(app_id) do
        {:ok, authorize_url} ->
          socket
          |> put_flash(:info, "Redirecting to provider authorization page.")
          |> redirect(external: authorize_url)

        {:error, _error_msg} ->
          socket
          |> put_flash(
            :error,
            "There was an error redirecting you to the provider authorization page."
          )
      end

    {:noreply, socket}
  end
end
