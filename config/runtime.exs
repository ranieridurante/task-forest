import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/task_forest start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :task_forest, TaskForestWeb.Endpoint, server: true
end

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: {System, :get_env, ["GOOGLE_CLIENT_ID"]},
  client_secret: {System, :get_env, ["GOOGLE_CLIENT_SECRET"]}

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET")

config :task_forest, TaskForest.Encryption,
  # get the ENCRYPTION_KEYS env variable
  keys:
    System.get_env("ENCRYPTION_KEYS")
    # remove single-quotes around key list in .env
    |> String.replace("'", "")
    # split the CSV list of keys
    |> String.split(",")
    # decode the key.
    |> Enum.map(fn key -> :base64.decode(key) end)

posthog_enabled = System.get_env("POSTHOG_ENABLED") || "false"

config :task_forest, :posthog,
  is_enabled: posthog_enabled == "true",
  api_key: System.get_env("POSTHOG_API_KEY"),
  endpoint: System.get_env("POSTHOG_ENDPOINT")

config :task_forest, :google_cloud_services,
  plomb_media_service_credentials: System.get_env("GOOGLE_PLOMB_MEDIA_SERVICE_CREDENTIALS_JSON") |> Jason.decode!(),
  media_bucket: System.get_env("GCS_MEDIA_BUCKET") || "dev-plomb-media"

config :task_forest, :postmark,
  url: "https://api.postmarkapp.com/email",
  token: System.get_env("POSTMARK_SERVER_TOKEN")

# Configuring Tesla to use Mint in the beginning to avoid issues
# with clients making http requests on startup
config :tesla, :adapter, Tesla.Adapter.Mint

# Load users with admin access.
admin_emails =
  "ADMIN_EMAILS"
  |> System.get_env("ADMIN_EMAILS")
  |> String.split(",")

config :task_forest,
  admin_emails: admin_emails,
  stripe_webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET"),
  openrouter_api_key: System.get_env("OPENROUTER_API_KEY")

with :prod <- config_env(),
     {:ok, _} <- Application.ensure_all_started(:tesla) do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  db_conn_ssl = System.get_env("DB_CONN_SSL") || "false"

  is_main_server = System.get_env("IS_MAIN_SERVER", "false")

  config :task_forest, TaskForest.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    migrations_enabled: true,
    ssl: db_conn_ssl == "true",
    # TODO: set the ssl_opts to verify the server's certificate
    ssl_opts: [verify: :verify_none, log_level: :error]

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")
  check_origin_host = System.get_env("CHECK_ORIGIN_HOST") || host

  config :task_forest, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :task_forest, TaskForestWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    check_origin: ["https://#{check_origin_host}"],
    secret_key_base: secret_key_base

  # Reconfiguring Tesla adapter to use Finch
  config :tesla, :adapter, {Tesla.Adapter.Finch, name: TaskForestFinch}

  logger_level = System.get_env("LOGGER_LEVEL") || "info"

  config :logger, level: String.to_atom(logger_level)

  main_server_crontab = []

  crontab =
    if is_main_server == "true" do
      main_server_crontab
    else
      []
    end

  config :task_forest, Oban,
    plugins: [
      {Oban.Pro.Plugins.DynamicCron, crontab: crontab},
      {Oban.Pro.Plugins.DynamicPruner, mode: {:max_age, {14, :days}}, worker_overrides: []},
      {Oban.Pro.Plugins.DynamicPrioritizer, after: :timer.minutes(20)},
      {Oban.Pro.Plugins.DynamicLifeline, rescue_interval: :timer.minutes(30)},
      {
        Oban.Pro.Plugins.DynamicQueues,
        # TODO: Increase default and scheduled_triggers queues after migrating to larger DB
        queues: [
          default: 5,
          credits: 5,
          max_concurrency_5: 5,
          max_concurrency_3: 3,
          max_concurrency_2: 2,
          max_concurrency_1: 1,
          scheduled_triggers: 5
        ]
      }
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :task_forest, TaskForestWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :task_forest, TaskForestWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :task_forest, TaskForest.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
