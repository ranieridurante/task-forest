defmodule TaskForest.Tasks.Task do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  schema "tasks" do
    field :workflow_id, :string
    field :task_template_id, Ecto.UUID
    field :config_overrides, :map
    field :name, :string
    field :inputs_definition, :map
    field :outputs_definition, :map

    field :is_template_reference, :boolean, default: false
    field :template_reference_for_id, Ecto.UUID

    field :task_workflow_id, Ecto.UUID

    # TODO: remove
    field :prompt, :string

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :workflow_id,
      :name,
      :prompt,
      :inputs_definition,
      :outputs_definition,
      :updated_at,
      :inserted_at,
      :task_template_id,
      :config_overrides,
      :is_template_reference,
      :template_reference_for_id,
      :task_workflow_id
    ])
    |> validate_required([
      :workflow_id
    ])
  end
end
