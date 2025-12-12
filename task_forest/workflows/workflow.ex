defmodule TaskForest.Workflows.Workflow do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.WorkflowTemplates.WorkflowTemplate

  @derive {Jason.Encoder,
           only: [
             :id,
             :company_id,
             :name,
             :description,
             :config,
             :graph,
             :inputs_definition,
             :outputs_definition,
             :inserted_at,
             :updated_at,
             :template_reference_for_id
           ]}

  schema "workflows" do
    field :company_id, :string
    field :name, :string
    field :description, :string
    field :config, :map, default: %{}
    field :graph, :map, default: %{"steps" => [], "tasks" => []}
    field :inputs_definition, :map, default: %{}
    field :outputs_definition, :map, default: %{}

    field :template_reference_for_id, Ecto.UUID

    has_one :workflow_template, WorkflowTemplate

    timestamps()
  end

  @doc false
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [
      :company_id,
      :name,
      :description,
      :config,
      :updated_at,
      :inserted_at,
      :graph,
      :inputs_definition,
      :outputs_definition,
      :template_reference_for_id
    ])
    |> validate_required([:company_id, :name, :config])
    |> unique_constraint([:company_id, :name])
  end
end
