defmodule TaskForest.Providers.Provider do
  use TaskForest.SchemaTemplate
  import Ecto.Changeset

  alias TaskForest.Utils

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :slug,
             :keys,
             :instructions,
             :logo,
             :website,
             :stored_keys,
             :apps,
             :featured,
             :app_config_definition,
             :app_setup_instructions,
             :webhook_config
           ]}

  schema "providers" do
    field :name, :string
    field :slug, :string

    field :keys, :map,
      default: %{
        "example_api_key" => %{
          "required" => true,
          "name" => "Example API Key",
          "description" => "This is an example API key"
        }
      }

    field :instructions, :string

    # Check https://github.com/ueberauth/oauth2/blob/master/lib/oauth2/client.ex
    field :app_config_definition, :map,
      default: %{
        "client_id" => %{
          "required" => true,
          "name" => "Example Client ID",
          "description" => "This is an example"
        },
        "client_secret" => %{
          "required" => true,
          "name" => "Example Client Secret",
          "description" => "This is an example"
        },
        "redirect_uri" => %{
          "required" => false,
          "value" => "/another-callback-route",
          "hidden" => true
        }
      }

    field :webhook_config, :map,
      default: %{
        "verification" => %{
          "indicators" => %{
            "methods" => ["post"],
            "params" => %{
              "query" => ["challenge"],
              "headers" => ["X-Verification"],
              "body" => ["challenge"]
            },
            "payload_patterns" => %{
              "type" => "url_verification"
            }
          },
          "type" => "echo|hmac|token",
          "method" => "get|post",
          "source" => %{
            "key" => "hub.challenge",
            "location" => "query|body|headers"
          },
          "response" => %{
            "format" => "text|json",
            "content" => ">>CHALLENGE<<"
          },
          "secret" => %{
            "provider-key" => "client_secret"
          },
          "token" => ">>TOKEN<<"
        }
      }

    field :app_setup_instructions, :string

    field :logo, :string
    field :website, :string

    field :stored_keys, :map, virtual: true
    field :apps, :map, virtual: true

    field :active, :boolean, default: true
    field :featured, :boolean, default: false

    timestamps()
  end

  def changeset(provider, attrs) do
    attrs = Utils.parse_json_strings(attrs, ["keys", "app_config_definition", "webhook_config"])

    provider
    |> cast(attrs, [
      :name,
      :slug,
      :keys,
      :instructions,
      :app_config_definition,
      :app_setup_instructions,
      :logo,
      :website,
      :updated_at,
      :inserted_at,
      :active,
      :featured,
      :webhook_config
    ])
    |> validate_required([:name, :slug, :keys, :instructions, :logo, :website])
    |> unique_constraint([:slug])
  end
end
