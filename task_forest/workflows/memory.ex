defmodule TaskForest.Workflows.Memory do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :workflow_id,
             :data,
             :inserted_at,
             :updated_at
           ]}

  schema "workflow_memories" do
    field :workflow_id, :string
    field :data, :map

    timestamps()
  end

  @doc false
  def changeset(memory, attrs) do
    memory
    |> cast(attrs, [:workflow_id, :data])
    |> validate_required([:data, :workflow_id])
  end
end
