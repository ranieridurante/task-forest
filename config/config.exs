# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :task_forest,
  ecto_repos: [TaskForest.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  admin_emails: []

config :task_forest, TaskForest.Repo, migration_primary_key: [type: :uuid]

# Configures the endpoint
config :task_forest, TaskForestWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TaskForestWeb.ErrorHTML, json: TaskForestWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TaskForest.PubSub,
  live_view: [signing_salt: "cNvMeDyL"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :task_forest, TaskForest.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  task_forest: [
    args:
      ~w(js/app.ts --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  task_forest: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  colors: [enabled: true],
  utc_log: true,
  format: "$date-$time [$level] $message $metadata\n",
  metadata: [
    :request_id,
    :error,
    :reason,
    :body,
    :provider,
    :task,
    :task_name
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :task_forest, Oban,
  notifier: Oban.Notifiers.PG,
  engine: Oban.Pro.Engines.Smart,
  repo: TaskForest.Repo,
  plugins: [
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
    },
    Oban.Pro.Plugins.DynamicCron
  ]

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
