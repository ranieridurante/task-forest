defmodule TaskForest.Repo.Migrations.RemoveWorkflowSlug do
  use Ecto.Migration

  def change do
    alter table(:workflows) do
      remove :slug
    end
  end
end
