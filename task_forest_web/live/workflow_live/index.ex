defmodule TaskForestWeb.WorkflowLive.Index do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Tasks
  alias TaskForest.Workflows
  alias TaskForest.Workflows.GraphUtils

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

    socket =
      if workflows_data.workflows == [] do
        redirect(socket, to: "/workflows/new")
      else
        socket
        |> assign(:tasks_with_providers, workflows_data.tasks_with_providers)
        |> assign(:provider_styles, workflows_data.provider_styles)
        |> assign(:workflows, workflows_data.workflows)
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

    routes = [
      %{href: "/home", label: "Home", icon: "mingcute:home-7-fill"}
    ]

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

        workflow_data = %{
          id: workflow.id,
          name: workflow.name,
          description: workflow.description,
          graph: workflow.graph,
          api_endpoint: api_endpoint,
          workflow_inputs_definition: format_inputs_definition(workflow.inputs_definition),
          company_id: workflow.company_id,
          updated_at: workflow.updated_at
        }

        {workflow_data, task_ids}
      end)

    task_ids
    |> Tasks.get_task_providers_with_styles()
    |> Map.put(:workflows, workflows)
  end
end
