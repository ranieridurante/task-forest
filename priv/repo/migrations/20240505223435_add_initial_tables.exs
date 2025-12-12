defmodule TaskForest.Repo.Migrations.AddInitialTables do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string
      add :slug, :string
      add :ai_tokens, :map

      timestamps()
    end

    unique_index(:companies, [:slug])

    create table(:api_tokens) do
      add :company_id, :string
      add :token, :string
      add :alias, :string

      timestamps()
    end

    unique_index(:api_tokens, [:company_id, :alias])

    create table(:workflows) do
      add :name, :string
      add :description, :text
      add :slug, :string
      add :company_id, :string
      add :config, :map

      timestamps()
    end

    unique_index(:workflows, [:company_id, :slug])
    unique_index(:workflows, [:company_id, :name])

    create table(:executions) do
      add :workflow_id, :string
      add :status, :string
      add :inputs, :map
      add :outputs, :map
      add :inputs_hash, :string

      timestamps()
    end

    create table(:tasks) do
      add :workflow_id, :string
      add :name, :string
      add :prompt, :text
      add :inputs_definition, :map
      add :outputs_definition, :map
      add :phase, :integer
      add :pipe_to, :string

      timestamps()
    end

    unique_index(:tasks, [:workflow_id, :name])
  end
end
