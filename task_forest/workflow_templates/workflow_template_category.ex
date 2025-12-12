defmodule TaskForest.WorkflowTemplates.WorkflowTemplateCategory do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.WorkflowTemplates.Category
  alias TaskForest.WorkflowTemplates.WorkflowTemplate

  @derive {Jason.Encoder,
           only: [
             :id,
             :workflow_template_id,
             :category_id,
             :inserted_at,
             :updated_at
           ]}

  schema "workflow_template_categories" do
    belongs_to :workflow_template, WorkflowTemplate, foreign_key: :workflow_template_id
    belongs_to :category, Category, foreign_key: :category_id

    timestamps()
  end

  @doc false
  def changeset(workflow_template_category, attrs) do
    workflow_template_category
    |> cast(attrs, [:workflow_template_id, :category_id])
    |> validate_required([:workflow_template_id, :category_id])
  end
end
