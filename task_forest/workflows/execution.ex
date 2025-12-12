defmodule TaskForest.Workflows.Execution do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :workflow_id,
             :inputs,
             :outputs,
             :status,
             :inputs_hash,
             :inserted_at,
             :updated_at
           ]}

  schema "executions" do
    field :workflow_id, :string
    field :inputs, :map
    field :outputs, :map
    field :status, :string
    field :inputs_hash, :string

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(execution, attrs) do
    execution
    |> cast(attrs, [
      :workflow_id,
      :inputs,
      :outputs,
      :status,
      :inputs_hash,
      :updated_at,
      :inserted_at
    ])
    |> validate_required([:workflow_id, :inputs, :status, :inputs_hash])
  end
end
