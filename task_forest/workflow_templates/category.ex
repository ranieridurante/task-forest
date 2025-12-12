defmodule TaskForest.WorkflowTemplates.Category do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.WorkflowTemplates.WorkflowTemplate
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCategory

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :icon,
             :inserted_at,
             :updated_at,
             :slug
           ]}

  schema "categories" do
    field :name, :string
    field :icon, :string
    field :slug, :string

    has_many :workflow_template_categories, WorkflowTemplateCategory
    has_many :workflow_templates, through: [:workflow_template_categories, :workflow_template]

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :icon, :slug])
    |> validate_required([:name, :icon, :slug])
  end
end
