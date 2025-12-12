defmodule TaskForest.Providers.AppConfigDefinition do
  @moduledoc """
  Defines the structure and types for application configuration.
  """

  # This is a sample configuration for Instagram OAuth integration.
  # It includes the necessary steps to authorize a user, obtain an access token,
  # and exchange it for a long-lived access token.
  #
  #   %{
  #   user_fields: %{
  #     client_secret: %{
  #       name: "Instagram App Secret",
  #       required: true,
  #       description: "Instagram App Secret"
  #     },
  #     client_id: %{
  #       name: "Instagram App ID",
  #       required: true,
  #       description: "Instagram App ID"
  #     }
  #   },
  #   steps: [
  #     %{
  #       name: "authorization",
  #       handler: "authorize_url",
  #       host: "https://www.instagram.com",
  #       uri: "/oauth/authorize",
  #       redirect_uri: "",
  #       extra_params: %{
  #         response_type: "code",
  #         scope: ["business_basic", "business_content_publish", "business_manage_comments", "business_manage_messages"]
  #       },
  #       state_field: "state",
  #       error_fields: ["error", "error_reason", "error_description"]
  #     },
  #     %{
  #       name: "access_token",
  #       handler: "get_token",
  #       host: "https://api.instagram.com",
  #       uri: "/oauth/access_token",
  #       redirect_uri: "",
  #       extra_params: %{
  #         grant_type: "authorization_code",
  #         code: ">>CODE<<"
  #       },
  #       response_accesor: "['data'][0]"
  #     },
  #     %{
  #       name: "long_lived_access_token",
  #       handler: "get_token",
  #       host: "https://graph.instagram.com",
  #       http_method: "GET",
  #       uri: "/access_token",
  #       extra_params: %{
  #         access_token: ">>ACCESS_TOKEN<<",
  #         grant_type: "ig_exchange_token"
  #       }
  #     }
  #   ],
  #   defaults: %{}
  # }

  @type t :: %__MODULE__{
          user_fields: %{optional(String.t()) => UserField.t()},
          steps: [Step.t()],
          defaults: map()
        }

  defstruct user_fields: %{},
            steps: [],
            defaults: %{}
end

defmodule TaskForest.Providers.AppConfigDefinition.UserField do
  @moduledoc """
  Defines the structure and types for user fields in the configuration.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          required: boolean(),
          description: String.t()
        }

  defstruct name: "",
            required: false,
            description: ""
end

defmodule TaskForest.Providers.AppConfigDefinition.Step do
  @moduledoc """
  Defines the structure and types for steps in the configuration.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          handler: String.t(),
          host: String.t(),
          uri: String.t(),
          redirect_uri: String.t(),
          extra_params: map(),
          state_field: String.t() | nil,
          error_fields: [String.t()] | nil,
          response_accesor: String.t() | nil,
          http_method: String.t() | nil
        }

  defstruct name: "",
            handler: "",
            host: "",
            uri: "",
            redirect_uri: "",
            extra_params: %{},
            state_field: nil,
            error_fields: nil,
            response_accesor: nil,
            http_method: nil
end
