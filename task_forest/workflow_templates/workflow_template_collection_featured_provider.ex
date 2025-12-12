defmodule TaskForest.WorkflowTemplates.WorkflowTemplateCollectionFeaturedProvider do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :provider_slug,
             :workflow_template_collection_id,
             :inserted_at,
             :updated_at
           ]}

  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollection

  schema "workflow_template_collection_featured_providers" do
    field :provider_slug, :string

    belongs_to :workflow_template_collection, WorkflowTemplateCollection, foreign_key: :workflow_template_collection_id

    timestamps()
  end

  @doc false
  def changeset(workflow_template_collection_featured_provider, attrs) do
    workflow_template_collection_featured_provider
    |> cast(attrs, [:workflow_template_collection_id, :provider_slug])
    |> validate_required([:workflow_template_collection_id, :provider_slug])
  end
end
