defmodule TaskForest.Models.AiPrompt do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  schema "ai_prompt" do
    field :text, :string
    field :company_id, :string
    field :access_type, :string, default: "private"
    field :suggested_config, :map
    field :inputs_definition, :map
    field :outputs_definition, :map
    field :name, :string
    field :description, :string
    field :creator_id, Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :text,
      :company_id,
      :access_type,
      :suggested_config,
      :inputs_definition,
      :outputs_definition,
      :name,
      :description,
      :creator_id,
      :updated_at,
      :inserted_at
    ])
    |> validate_required([
      :text,
      :creator_id,
      :company_slug,
      :suggested_config,
      :inputs_definition,
      :outputs_definition,
      :name,
      :description
    ])
  end
end
