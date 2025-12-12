defmodule TaskForest.WorkflowTemplates.WorkflowTemplate do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Workflows.Workflow
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCategory

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :short_description,
             :markdown_description,
             :markdown_instructions,
             :created_by_type,
             :created_by_id,
             :image_url,
             :featured,
             :published,
             :inserted_at,
             :updated_at,
             :workflow_id,
             :tasks_updated_at,
             :provider_slugs,
             :slug,
             :usage_count
           ]}

  schema "workflow_templates" do
    field :name, :string
    field :short_description, :string
    field :markdown_description, :string
    field :markdown_instructions, :string
    field :created_by_type, :string
    field :created_by_id, :string
    field :image_url, :string
    field :featured, :boolean, default: false
    field :published, :boolean, default: false

    field :tasks_updated_at, :naive_datetime
    field :provider_slugs, :string
    field :slug, :string
    field :usage_count, :integer, default: 0

    belongs_to :workflow, Workflow, foreign_key: :workflow_id

    has_many :workflow_template_categories, WorkflowTemplateCategory
    has_many :categories, through: [:workflow_template_categories, :category]

    timestamps()
  end

  @doc false
  def changeset(workflow_template, attrs) do
    workflow_template
    |> cast(attrs, [
      :name,
      :short_description,
      :markdown_description,
      :markdown_instructions,
      :created_by_type,
      :created_by_id,
      :image_url,
      :featured,
      :published,
      :tasks_updated_at,
      :provider_slugs,
      :slug,
      :usage_count,
      :workflow_id
    ])
    |> validate_required([
      :name,
      :short_description,
      :created_by_type,
      :created_by_id,
      :tasks_updated_at,
      :provider_slugs,
      :slug,
      :workflow_id
    ])
  end
end
