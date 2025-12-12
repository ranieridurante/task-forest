defmodule TaskForest.Repo.Migrations.AddMagicFormsTable do
  use Ecto.Migration

  def up do
    create table(:magic_forms) do
      add :workflow_id, references(:workflows, on_delete: :delete_all)
      add :inputs_definition, :map
      add :user_request, :text
      add :html, :text
      add :name, :string

      timestamps()
    end
  end

  def down do
    drop table(:magic_forms)
  end
end
