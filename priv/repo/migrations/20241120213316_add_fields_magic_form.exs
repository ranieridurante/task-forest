defmodule TaskForest.Repo.Migrations.AddFieldsMagicForm do
  use Ecto.Migration

  def up do
    alter table(:magic_forms) do
      add :config, :map
      add :views_count, :integer, default: 0
      add :submissions_count, :integer, default: 0
    end
  end

  def down do
    alter table(:magic_forms) do
      remove :config
      remove :views_count
      remove :submissions_count
    end
  end
end
