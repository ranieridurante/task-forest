defmodule TaskForestWeb.Router do
  use TaskForestWeb, :router

  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

  alias TaskForestWeb.Plugs.ApiAuthPlug
  alias TaskForestWeb.Plugs.OrgPermissionsPlug
  alias TaskForestWeb.AuthPlug
  alias TaskForestWeb.InitAssignsAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TaskForestWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    plug AuthPlug, requires_auth: true, admin_only: true
  end

  pipeline :authenticated do
    plug AuthPlug, requires_auth: true
  end

  pipeline :unauthenticated do
    plug AuthPlug, requires_auth: false
  end

  pipeline :can_manage_billing do
    plug OrgPermissionsPlug, allowed_roles: ["billing_manager"]
  end

  pipeline :can_list_provider_keys do
    plug OrgPermissionsPlug, allowed_roles: ["credentials_manager"]
  end

  pipeline :can_list_workflows do
    plug OrgPermissionsPlug,
      allowed_roles: [
        "workflow_builder",
        "workflow_api_integrator",
        "workflow_user",
        "credentials_manager"
      ]
  end

  pipeline :can_open_canvas do
    plug OrgPermissionsPlug, allowed_roles: ["workflow_builder"]
  end

  pipeline :can_open_developer_zone do
    plug OrgPermissionsPlug, allowed_roles: ["workflow_api_integrator"]
  end

  pipeline :can_open_dashboard do
    plug OrgPermissionsPlug,
      allowed_roles: ["workflow_user", "workflow_builder", "workflow_api_integrator"]
  end

  pipeline :api do
    plug :accepts, ["json"]

    # NOTE: Check endpoint.ex for the Stripe Webhook route
  end

  pipeline :authenticated_api do
    plug :accepts, ["json"]

    plug ApiAuthPlug
  end

  scope "/", TaskForestWeb do
    pipe_through :browser

    scope "/admin" do
      pipe_through :admin

      oban_dashboard("/oban")

      live_dashboard "/dashboard", metrics: TaskForestWeb.Telemetry

      live_session :admin, on_mount: InitAssignsAuth do
        live "/providers", ProviderLive.Index, :index
        live "/providers/new", ProviderLive.Index, :new
        live "/providers/:id/edit", ProviderLive.Index, :edit
        live "/providers/:id", ProviderLive.Show, :show
        live "/providers/:id/show/edit", ProviderLive.Show, :edit

        live "/task-templates", TaskTemplateLive.Index, :index
        live "/task-templates/new", TaskTemplateLive.Index, :new
        live "/task-templates/:id/edit", TaskTemplateLive.Index, :edit
        live "/task-templates/:id", TaskTemplateLive.Show, :show
        live "/task-templates/:id/show/edit", TaskTemplateLive.Show, :edit

        live "/workflow-templates", WorkflowTemplatesLive.Index, :index
        live "/workflow-templates/new", WorkflowTemplatesLive.Index, :new
        live "/workflow-templates/:id/edit", WorkflowTemplatesLive.Index, :edit

        live "/workflow-templates/:id", WorkflowTemplatesLive.Show, :show
        live "/workflow-templates/:id/show/edit", WorkflowTemplatesLive.Show, :edit
      end
    end

    scope "/" do
      pipe_through :unauthenticated

      get "/", PageController, :home

      get "/login", AuthController, :login_page
      get "/signup", AuthController, :signup_page

      get "/auth/:provider", AuthController, :request
      get "/auth/:provider/callback", AuthController, :callback

      get "/apps/:app_id/callback",
          AuthController,
          :provider_app_callback

      # Render public magic form
      live "/magic-forms/:magic_form_id",
           WorkflowLive.RenderMagicForm,
           :render
    end

    live_session :authenticated, on_mount: InitAssignsAuth do
      scope "/" do
        pipe_through :authenticated

        get "/logout", AuthController, :logout

        # TODO: make public
        live "/market", MarketplaceLive.Index, :index
        live "/market/search", MarketplaceLive.Index, :search
        live "/market/collections/:slug", MarketplaceLive.Index, :by_collection
        live "/market/categories/:slug", MarketplaceLive.Index, :by_category
        live "/market/providers/:slug", MarketplaceLive.Index, :by_provider
        live "/market/workflow-templates/:slug", MarketplaceLive.Show, :show

        live "/workflows/:workflow_id/magic-forms", WorkflowLive.MagicForms, :index

        live "/magic-forms/:magic_form_id/editor", WorkflowLive.RenderMagicForm, :editor

        live "/home", HomeLive.Main, :index

        scope "/" do
          pipe_through :can_list_workflows

          live "/workflows", WorkflowLive.Index, :index
        end

        scope "/" do
          pipe_through :can_open_canvas

          live "/workflows/:workflow_id", WorkflowLive.Editor, :editor
        end

        scope "/" do
          pipe_through :can_open_developer_zone

          live "/api-keys", APIKeysLive.Main, :index
          live "/workflows/:workflow_id/playground", PlaygroundLive.Main, :index
          live "/workflows/:workflow_id/api-documentation", WorkflowLive.Show, :api_documentation
        end

        scope "/" do
          pipe_through :can_open_dashboard

          live "/workflows/:workflow_id/app-dashboard", WorkflowLive.Show, :app_dashboard
        end

        # TODO: implement prompt management
        # live "/prompts", PromptsLive.Index, :index

        scope "/" do
          pipe_through :can_list_provider_keys

          live "/provider-keys", IntegrationsLive.Index, :index
        end

        scope "/" do
          pipe_through :can_manage_billing

          live "/billing", BillingLive.Index, :index
        end
      end
    end
  end

  # Misc API endpoints
  scope "/", TaskForestWeb do
    pipe_through :api

    get "/health", HealthController, :check
  end

  # v1 Public API
  scope "/v1", TaskForestWeb do
    pipe_through :api

    get "/health", HealthController, :check

    match :*, "/:company_slug/:workflow_id/webhooks/:provider_slug", WorkflowController, :handle_webhook
  end

  # v1 API Requires Company Auth Token
  scope "/v1/:company", TaskForestWeb do
    pipe_through :authenticated_api

    post "/:workflow", WorkflowController, :execute

    get "/:workflow/executions/:execution_id",
        WorkflowController,
        :retrieve_execution_results
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:task_forest, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
