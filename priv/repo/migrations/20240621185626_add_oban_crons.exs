defmodule TaskForest.Repo.Migrations.AddObanCrons do
  use Ecto.Migration

  defdelegate change, to: Oban.Pro.Migrations.DynamicCron
end
