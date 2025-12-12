defmodule TaskForestWeb.Plugs.ApiAuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  alias TaskForest.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with %{"company" => company_slug} <- conn.params,
         ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         true <- Accounts.validate_auth_token(token, company_slug) do
      conn
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
        |> halt()
    end
  end
end
