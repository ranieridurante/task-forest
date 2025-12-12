defmodule TaskForestWeb.AuthController do
  use TaskForestWeb, :controller
  plug Ueberauth

  alias TaskForest.Accounts
  alias TaskForest.Marketing
  alias TaskForest.Providers
  alias TaskForest.WorkflowTemplates
  alias TaskForestWeb.Layouts

  def login_page(conn, params) do
    user_info = conn.assigns.user_info

    product_updates = Marketing.list_recent_product_updates(5)

    featured_provider =
      if params["provider"] do
        Providers.get_provider_by_slug(params["provider"])
      end

    featured_workflow_template =
      if params["workflow-template"] do
        WorkflowTemplates.get_workflow_template_by_slug(params["workflow-template"])
      end

    template_providers =
      if featured_workflow_template do
        slugs = String.split(featured_workflow_template.provider_slugs, ",")

        Providers.list_providers_by_slug(slugs)
      end

    query_params = maybe_encode_query_params(params)

    if user_info != nil do
      conn
      |> put_flash(:info, "Looks like you’re still logged in!")
      |> redirect(to: "/dashboard")
    else
      render(conn, :login,
        layout: {Layouts, :auth},
        product_updates: product_updates,
        featured_provider: featured_provider,
        featured_workflow_template: featured_workflow_template,
        template_providers: template_providers,
        query_params: query_params
      )
    end
  end

  def signup_page(conn, params) do
    user_info = conn.assigns.user_info

    featured_provider =
      if params["provider"] do
        Providers.get_provider_by_slug(params["provider"])
      end

    featured_workflow_template =
      if params["workflow-template"] do
        WorkflowTemplates.get_workflow_template_by_slug(params["workflow-template"])
      end

    template_providers =
      if featured_workflow_template do
        slugs = String.split(featured_workflow_template.provider_slugs, ",")

        Providers.list_providers_by_slug(slugs)
      end

    query_params = maybe_encode_query_params(params)

    if user_info != nil do
      conn
      |> put_flash(:info, "Looks like you’re still logged in!")
      |> redirect(to: "/dashboard")
    else
      render(conn, :signup, layout: {Layouts, :auth},  featured_provider: featured_provider,
      featured_workflow_template: featured_workflow_template, template_providers: template_providers, query_params: query_params)
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_resp_cookie("session_token",
      encrypt: true,
      max_age: Accounts.session_expiration()
    )
    |> put_flash(:info, "You’re all signed out. Have a great day!")
    |> redirect(to: "/login")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Oops, something went wrong. Please try again!")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth_data}} = conn, _params) do
    user_info = %{
      email: auth_data.info.email,
      first_name: auth_data.info.first_name,
      last_name: auth_data.info.last_name,
      is_plomb_admin: is_plomb_admin?(auth_data.info.email)
    }

    case Accounts.create_session_storing_user(user_info) do
      {:ok,
       %{
         updated_user: user,
         active_company: active_company,
         companies_before_session: companies_before_session
       }} ->
        user_companies = companies_before_session || [active_company]

        # If companies_before_session is nil, it means this is the first time the user is logging in
        if companies_before_session == [] do
          Accounts.add_new_account_credits(active_company.id)
        end

        conn
        |> put_session(:user_id, user.id)
        |> put_session(:user_info, user_info)
        |> put_session(:active_company, active_company)
        |> put_session(:user_companies, user_companies)
        |> put_resp_cookie("session_token", user_info,
          encrypt: true,
          max_age: Accounts.session_expiration()
        )
        |> put_flash(:info, "You're in!")
        |> redirect(to: "/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Oops, something went wrong. Please try again!")
        |> redirect(to: "/")
    end
  end

  def provider_app_callback(conn, %{"state" => state, "code" => code} = params) do
    with {:ok, decoded_state} <- Providers.verify_and_decode_oauth2_state(state),
         :ok <- Providers.process_oauth2_code(decoded_state, code) do
      conn
      |> put_flash(:info, "Successfully connected a new account.")
      |> redirect(to: "/provider-keys")
    else
      {:error, _error_message} ->
        conn
        |> put_flash(:error, "There was an error connecting your account.")
        |> redirect(to: "/provider-keys")
    end
  end

  def provider_app_callback(conn, %{"code" => code, "app_id" => app_id} = _params) do
    case Providers.process_oauth2_access_token(app_id, code) do
      {:ok, _data} ->
        conn
        |> put_flash(:info, "Successfully connected a new account.")
        |> redirect(to: "/provider-keys")

      {:error, _error_message} ->
        conn
        |> put_flash(:error, "There was an error connecting your account.")
        |> redirect(to: "/provider-keys")
    end
  end

  defp is_plomb_admin?(user_email) do
    admin_emails = Application.get_env(:task_forest, :admin_emails)

    user_email in admin_emails
  end

  defp maybe_encode_query_params(params) when is_map(params) do
    "?" <> URI.encode_query(params)
  end

  defp maybe_encode_query_params(_params) do
    ""
  end
end
