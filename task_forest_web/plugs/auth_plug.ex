defmodule TaskForestWeb.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, [requires_auth: true, admin_only: true] = _opts) do
    app_env = Application.get_env(:task_forest, :env)

    conn
    |> fetch_cookies(encrypted: ["session_token"])
    |> check_auth()
    |> then(fn conn ->
      if app_env == :prod do
        check_admin(conn)
      else
        conn
      end
    end)
  end

  def call(conn, [requires_auth: true] = _opts) do
    conn
    |> fetch_cookies(encrypted: ["session_token"])
    |> check_auth()
  end

  def call(conn, [requires_auth: false] = _opts) do
    conn
    |> fetch_cookies(encrypted: ["session_token"])
    |> assign(:user_info, nil)
  end

  def check_auth(conn) do
    case conn.cookies["session_token"] do
      nil ->
        conn
        |> assign(:user_info, nil)
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/login")

      _session_token ->
        user_info = get_session(conn, :user_info)
        user_companies = get_session(conn, :user_companies)
        active_company = get_session(conn, :active_company)

        conn
        |> assign(:user_info, user_info)
        |> assign(:user_companies, user_companies)
        |> assign(:active_company, active_company)
        |> assign(:allow_org_switch, true)
    end
  end

  def check_admin(%{assigns: %{user_info: %{email: email}}} = conn) do
    admin_emails = Application.get_env(:task_forest, :admin_emails)

    if email in admin_emails do
      conn
    else
      conn
      |> assign(:user_info, nil)
      |> put_flash(:error, "You don't have permission to access this page.")
      |> redirect(to: "/")
    end
  end
end
