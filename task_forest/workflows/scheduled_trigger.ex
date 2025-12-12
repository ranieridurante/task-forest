defmodule TaskForest.Workflows.ScheduledTrigger do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :workflow_id,
             :inputs,
             :active,
             :cron_expression,
             :inserted_at,
             :updated_at
           ]}

  schema "scheduled_triggers" do
    field :name, :string
    field :workflow_id, :string
    field :inputs, :map
    field :active, :boolean, default: true
    field :cron_expression, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scheduled_trigger, attrs) do
    scheduled_trigger
    |> cast(attrs, [
      :name,
      :workflow_id,
      :inputs,
      :active,
      :inserted_at,
      :updated_at,
      :cron_expression
    ])
    |> validate_required([:name, :workflow_id, :inputs, :cron_expression])
  end
end
