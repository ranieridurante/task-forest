defmodule TaskForestWeb.Plugs.OrgPermissionsPlug do
  import Phoenix.Controller

  alias TaskForest.Accounts

  def init(opts), do: opts

  def call(conn, [allowed_roles: allowed_roles] = _opts) do
    active_company = conn.assigns[:active_company]

    roles = active_company[:roles]

    user_has_permission = Accounts.user_has_permission(active_company, allowed_roles)

    cond do
      roles == nil ->
        conn
        |> redirect(to: "/logout")

      user_has_permission == false ->
        conn
        |> put_flash(
          :error,
          "You do not have permission to access this page. Ask your admin for access."
        )
        |> redirect(to: "/")

      true ->
        conn
    end
  end
end
