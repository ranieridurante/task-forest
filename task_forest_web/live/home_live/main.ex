defmodule TaskForestWeb.HomeLive.Main do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Tasks
  alias TaskForest.Utils
  alias TaskForest.Workflows
  alias TaskForest.WorkflowTemplates

  @impl true
  @spec mount(any(), any(), map()) :: {:ok, map()}
  def mount(
        _params,
        _session,
        %{assigns: %{active_company: active_company, user_info: user_info}} = socket
      ) do
    company = Accounts.get_company_by_slug(active_company.slug)

    socket =
      socket
      |> assign(:workflows, [])
      |> assign(:tasks_with_providers, %{})
      |> assign(:provider_styles, %{})
      |> assign(:company, company)
      |> assign(:user_info, user_info)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{company: company}} = socket) do
    workflows_data = get_workflows_data(company)

    shortcuts = [
      %{
        name: "Connected Services",
        description: "Manage your organization connections to external services",
        icon: "tdesign:app",
        link: "/provider-keys"
      },
      %{
        name: "Templates Market",
        description: "Explore workflow templates created by other users.",
        icon: "material-symbols:storefront-outline",
        link: "/market"
      },
      %{
        name: "API Keys",
        description: "Manage your organization API keys for Plomb.",
        icon: "material-symbols:key-outline-rounded",
        link: "/api-keys"
      },
      %{
        name: "Billing",
        description: "Manage subscriptions, buy credits and see your organization transaction history.",
        icon: "ph:credit-card-bold",
        link: "/billing"
      }
    ]

    socket =
      if workflows_data.workflows == [] do
        redirect(socket, to: "/workflows/new")
      else
        socket
        |> assign(:tasks_with_providers, workflows_data.tasks_with_providers)
        |> assign(:provider_styles, workflows_data.provider_styles)
        |> assign(:workflows, workflows_data.workflows)
        |> assign(:shortcuts, shortcuts)
        |> apply_action(:index, params)
      end

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(
         %{assigns: %{company: company}} = socket,
         :index,
         _params
       ) do
    workflows_data = get_workflows_data(company)

    routes = []

    socket
    |> assign(:page_title, "Workflows")
    |> assign(:tasks_with_providers, workflows_data.tasks_with_providers)
    |> assign(:provider_styles, workflows_data.provider_styles)
    |> assign(:workflows, workflows_data.workflows)
    |> assign(:routes, routes)
  end

  @impl true
  def handle_event("react.go_to_canvas", %{"workflow_id" => workflow_id}, socket) do
    {:noreply, redirect(socket, to: "/workflows/#{workflow_id}")}
  end

  def handle_event("react.create_workflow", params, socket) do
    socket =
      case Workflows.create_workflow(params) do
        {:ok, %{workflow: workflow}} ->
          redirect(socket, to: "/workflows/#{workflow.id}")

        {:error, _error_msg} ->
          put_flash(socket, :error, "Failed to create workflow")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.duplicate_workflow",
        %{"workflow_id" => workflow_id},
        %{assigns: %{active_company: active_company} = _assigns} = socket
      ) do
    socket =
      case Workflows.duplicate_workflow(active_company.id, workflow_id) do
        {:ok, workflow} ->
          socket
          |> put_flash(:info, "Successfully duplicated your workflow.")
          |> redirect(to: "/workflows/#{workflow.id}")

        {:error, _error_msg} ->
          put_flash(socket, :error, "Failed to duplicate workflow")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_workflow",
        %{"workflow_id" => workflow_id},
        %{assigns: %{workflows: workflows}} = socket
      ) do
    Workflows.delete_workflow(workflow_id)

    workflows = Enum.reject(workflows, fn workflow -> workflow.id == workflow_id end)

    socket =
      socket
      |> assign(:workflows, workflows)
      |> put_flash(:info, "Your workflow has been deleted.")
      |> push_event("server.workflow_deleted", %{
        workflow_id: workflow_id
      })

    {:noreply, socket}
  end

  def handle_event(
        "react.create_workflow_template",
        %{"workflow_id" => workflow_id, "publish_as" => publish_as} = params,
        %{assigns: %{company: company, user_id: user_id, workflows: workflows}} = socket
      ) do
    created_by_id =
      case publish_as do
        "user" -> user_id
        "organization" -> company.id
      end

    created_by_type = if publish_as == "user", do: "user", else: "company"

    params =
      Map.merge(params, %{
        "created_by_id" => created_by_id,
        "created_by_type" => created_by_type
      })

    socket =
      case WorkflowTemplates.create_workflow_template(params) do
        {:ok, workflow_template} ->
          workflow_template_data =
            Map.take(workflow_template, [
              "published",
              "featured",
              "tasks_updated_at",
              "slug"
            ])

          workflows =
            Utils.update_map_keys_by_key(workflows, :id, workflow_id, %{
              workflow_template: workflow_template_data
            })

          workflow_template_uri = "/market/workflow-templates/#{workflow_template.slug}"

          socket
          |> assign(:workflows, workflows)
          |> put_flash(:info, "Your workflow template has been created.")
          |> redirect(to: workflow_template_uri)

        {:error, _} ->
          socket
          |> put_flash(:error, "There was an error creating your workflow template.")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.switch_organization",
        %{"new_active_company_slug" => new_active_company_slug} = _params,
        %{
          assigns: %{
            user_id: user_id,
            user_companies: user_companies
          }
        } = socket
      ) do
    Accounts.update_user_active_company(user_id, new_active_company_slug)

    active_company = Enum.find(user_companies, &(new_active_company_slug == &1.slug))

    socket =
      socket
      |> assign(:active_company, active_company)
      |> assign(:company, active_company)
      |> put_flash(:info, "Switched to #{active_company.name}")
      |> apply_action(:index, %{})
      |> push_event("server.switch_organization", %{
        new_active_company: active_company
      })
      |> push_navigate(to: "/", replace: true)

    {:noreply, socket}
  end

  # TODO: generate string that describes expected
  # field format and use placeholder if any
  defp format_inputs_definition(inputs_definition) do
    Enum.reduce(inputs_definition, %{}, fn {key, value}, acc ->
      Map.put(acc, key, value["type"])
    end)
  end

  def get_workflows_data(company) do
    {workflows, task_ids} =
      company.id
      |> Workflows.get_company_workflows()
      |> Enum.map_reduce([], fn workflow, task_ids ->
        api_endpoint = "https://api.plomb.ai/v1/#{company.slug}/#{workflow.id}"

        task_ids = task_ids ++ workflow.graph["tasks"]

        workflow_template =
          if workflow.workflow_template != nil do
            Map.take(workflow.workflow_template, [
              :featured,
              :published,
              :tasks_updated_at,
              :slug,
              :usage_count
            ])
          end

        complexity = calculate_workflow_complexity(workflow.graph)

        workflow_data = %{
          id: workflow.id,
          name: workflow.name,
          description: workflow.description,
          graph: workflow.graph,
          api_endpoint: api_endpoint,
          workflow_inputs_definition: format_inputs_definition(workflow.inputs_definition),
          company_id: workflow.company_id,
          inserted_at: workflow.inserted_at,
          updated_at: workflow.updated_at,
          workflow_template: workflow_template,
          complexity: complexity
        }

        {workflow_data, task_ids}
      end)

    task_ids
    |> Tasks.get_task_providers_with_styles()
    |> Map.put(:workflows, workflows)
  end

  defp calculate_workflow_complexity(%{"tasks" => []}) do
    0
  end

  defp calculate_workflow_complexity(%{"tasks" => tasks} = graph) do
    has_iterator =
      Enum.any?(graph["steps"] || [], fn %{"s" => _, "t" => target} ->
        String.starts_with?(target, "iter_")
      end)

    cond do
      has_iterator -> 3
      map_size(Map.get(graph, "filters", %{})) > 0 -> 2
      length(tasks) >= 4 -> 3
      length(tasks) >= 2 -> 2
      true -> 1
    end
  end
end
