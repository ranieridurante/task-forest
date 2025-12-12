defmodule TaskForest.Repo.Migrations.AddTaskTemplates do
  use Ecto.Migration

  def change do
    create table(:task_templates) do
      add :name, :string
      add :description, :string
      add :config, :map
      add :inputs_definition, :map
      add :outputs_definition, :map
      add :provider_slug, :string
      add :style, :map
      add :creator_id, references(:users, on_delete: :nothing)
      add :company_slug, :string
      add :access_type, :string

      timestamps()
    end

    alter table(:tasks) do
      add :task_template_id, references(:task_templates, on_delete: :nothing)
      add :config_overrides, :map
    end

    create table(:ai_prompts) do
      add :text, :text
      add :creator_id, references(:users, on_delete: :nothing)
      add :company_slug, :string
      add :access_type, :string
      add :suggested_config, :map
      add :inputs_definition, :map
      add :outputs_definition, :map
      add :name, :string
      add :description, :string

      timestamps()
    end
  end
end
