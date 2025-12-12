defmodule TaskForest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ensure_session_table_exists()

    children = [
      TaskForestWeb.Telemetry,
      TaskForest.Repo,
      {DNSCluster, query: Application.get_env(:task_forest, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TaskForest.PubSub},
      {Finch, name: TaskForestFinch, pools: %{:default => [size: 500, count: 8]}},
      # Start a worker by calling: TaskForest.Worker.start_link(arg)
      # {TaskForest.Worker, arg},
      {Oban, Application.fetch_env!(:task_forest, Oban)},
      {Goth,
       name: TaskForestGoth,
       source:
         {:service_account, Application.get_env(:task_forest, :google_cloud_services)[:plomb_media_service_credentials]}},

      # Start to serve requests, typically the last entry
      TaskForestWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TaskForest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp ensure_session_table_exists do
    if :ets.info(:session) == :undefined do
      :ets.new(:session, [:set, :public, :named_table])
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TaskForestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
