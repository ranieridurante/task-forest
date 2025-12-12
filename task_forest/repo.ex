defmodule TaskForest.Repo do
  use Ecto.Repo,
    otp_app: :task_forest,
    adapter: Ecto.Adapters.Postgres,
    # Reducing the pool size to 5 to avoid overloading the database
    pool_size: 5
end
