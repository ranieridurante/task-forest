defmodule TaskForest.WorkflowTemplates.WorkflowTemplateCollectionWorkflowTemplate do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :workflow_template_collection_id,
             :workflow_template_id,
             :inserted_at,
             :updated_at
           ]}

  alias TaskForest.WorkflowTemplates.WorkflowTemplate
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollection

  schema "workflow_template_collection_workflow_templates" do
    belongs_to :workflow_template_collection, WorkflowTemplateCollection, foreign_key: :workflow_template_collection_id

    belongs_to :workflow_template, WorkflowTemplate, foreign_key: :workflow_template_id

    timestamps()
  end

  @doc false
  def changeset(workflow_template_collection_workflow_template, attrs) do
    workflow_template_collection_workflow_template
    |> cast(attrs, [:workflow_template_collection_id, :workflow_template_id])
    |> validate_required([:workflow_template_collection_id, :workflow_template_id])
  end
end
