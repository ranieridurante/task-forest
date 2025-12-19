defmodule TaskForest.Repo.Migrations.ChangeTaskTemplateDescriptionType do
  use Ecto.Migration

  def change do
    alter table(:task_templates) do
      modify :description, :text, from: :string
    end
  end
end
