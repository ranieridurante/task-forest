defmodule TaskForest.WorkflowTemplates.WorkflowTemplateCollection do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Providers.Provider
  alias TaskForest.WorkflowTemplates.WorkflowTemplate
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollectionFeaturedProvider
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollectionWorkflowTemplate

  @derive {Jason.Encoder,
           only: [
             :id,
             :title,
             :short_description,
             :image_url,
             :markdown_description,
             :inserted_at,
             :updated_at,
             :featured_providers,
             :workflow_templates,
             :slug
           ]}

  schema "workflow_template_collections" do
    field :title, :string
    field :short_description, :string
    field :image_url, :string
    field :markdown_description, :string
    field :slug, :string

    has_many :workflow_template_collection_workflow_templates,
             WorkflowTemplateCollectionWorkflowTemplate

    has_many :workflow_templates,
      through: [:workflow_template_collection_workflow_templates, :workflow_template]

    has_many :featured_providers,
             WorkflowTemplateCollectionFeaturedProvider

    timestamps()
  end

  @doc false
  def changeset(workflow_template_collection, attrs) do
    workflow_template_collection
    |> cast(attrs, [
      :title,
      :short_description,
      :image_url,
      :markdown_description,
      :slug
    ])
    |> validate_required([:title, :slug])
  end
end
