defmodule TaskForest.Repo.Migrations.AddReferenceFieldWorkflows do
  use Ecto.Migration

  def up do
    alter table(:workflows) do
      add :template_reference_for_id,
          references(:workflows, column: :id, type: :uuid, on_delete: :delete_all)
    end

    alter table(:tasks) do
      add :template_reference_for_id, :uuid
    end
  end

  def down do
    alter table(:workflows) do
      remove :template_reference_for_id
    end

    alter table(:tasks) do
      remove :template_reference_for_id
    end
  end
end
