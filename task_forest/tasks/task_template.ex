defmodule TaskForest.Tasks.TaskTemplate do
  use TaskForest.SchemaTemplate

  import Ecto.Changeset

  alias TaskForest.Utils

  @derive {Jason.Encoder,
           only: [
             :name,
             :description,
             :config,
             :inputs_definition,
             :outputs_definition,
             :provider_slug,
             :style,
             :access_type,
             :company_slug,
             :creator_id,
             :featured
           ]}

  schema "task_templates" do
    field :name, :string
    field :description, :string

    field :config, :map,
      default: %{
        max_concurrency: 1,
        outputs_mapper: %{
          "upscale_mj_task_id" => "result"
        },
        outputs_validations: %{
          "code" => %{
            "expected_value" => 1
          }
        },
        request_headers_definition: %{
          "Content-Type" => %{
            "value" => "application/json"
          },
          "mj-api-secret" => %{
            "provider_key" => "midjourney_api_secret"
          }
        },
        request_host: "https://midjourney.plomb.ai",
        request_method: "post",
        request_name: "upscale",
        request_params_definition: %{
          "action" => %{
            "value" => "UPSCALE"
          },
          "index" => %{
            "value" => 4
          },
          "taskId" => %{
            "path" => "imagine_mj_task_id",
            "type" => "string"
          }
        },
        request_uri: "/mj/submit/change",
        sleep_after: 30000,
        sleep_before: 60_000,
        available_models: [
          "gpt-4o",
          "gpt-4",
          "gpt-3.5-turbo"
        ],
        model_id: "gpt-4o",
        model_params: %{
          capability: "chat_completion",
          prompt:
            "Add your prompt, reference variables like this: >>MY_INPUT<< and don't forget to make references to your desired outputs variables. Reverse the input variable and return it.",
          response_format: %{
            type: "json_object"
          },
          temperature: 0.7
        },
        type: "http_request"
      }

    field :inputs_definition, :map,
      default: %{
        "imagine_mj_task_id" => %{
          "type" => "string"
        }
      }

    field :outputs_definition, :map,
      default: %{
        "imagine_mj_task_id" => %{
          "type" => "string"
        }
      }

    field :style, :map,
      default: %{
        background_color: "#93c5fd",
        border_color: "#18181b",
        icon: "logos:midjourney",
        icon_color: "#18181b",
        text_color: "#18181b"
      }

    field :creator_id, Ecto.UUID
    field :company_slug, :string
    field :access_type, :string, default: "private"
    field :provider_slug, :string
    field :featured, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    attrs =
      Utils.parse_json_strings(attrs, [
        "config",
        "inputs_definition",
        "outputs_definition",
        "style"
      ])

    task
    |> cast(attrs, [
      :name,
      :description,
      :config,
      :inputs_definition,
      :outputs_definition,
      :provider_slug,
      :style,
      :creator_id,
      :company_slug,
      :access_type,
      :updated_at,
      :inserted_at,
      :featured
    ])
    |> validate_required([
      :name,
      :config,
      :inputs_definition,
      :outputs_definition,
      :description,
      :access_type
    ])
  end
end
