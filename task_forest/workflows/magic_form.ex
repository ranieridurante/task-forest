defmodule TaskForest.Workflows.MagicForm do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Workflows.Workflow

  @derive {Jason.Encoder,
           only: [
             :id,
             :inputs_definition,
             :user_request,
             :html,
             :name,
             :config,
             :views_count,
             :submissions_count,
             :workflow_id,
             :inserted_at,
             :updated_at
           ]}

  schema "magic_forms" do
    field :inputs_definition, :map
    field :user_request, :string
    field :html, :string
    field :name, :string
    field :config, :map
    field :views_count, :integer, default: 0
    field :submissions_count, :integer, default: 0

    belongs_to :workflow, Workflow

    timestamps()
  end

  @doc false
  def changeset(magic_form, attrs) do
    magic_form
    |> cast(attrs, [
      :workflow_id,
      :inputs_definition,
      :user_request,
      :html,
      :name,
      :config,
      :views_count,
      :submissions_count
    ])
    |> validate_required([:workflow_id, :inputs_definition, :name])
    |> foreign_key_constraint(:workflow_id)
  end
end
