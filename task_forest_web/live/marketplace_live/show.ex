defmodule TaskForestWeb.MarketplaceLive.Show do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Providers
  alias TaskForest.WorkflowTemplates
  alias TaskForest.WorkflowTemplates.WorkflowTemplate

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    socket =
      case WorkflowTemplates.get_workflow_template_by_slug(slug) do
        %WorkflowTemplate{} = workflow_template ->
          user_id = socket.assigns.user_id
          active_company = socket.assigns.active_company
          # TODO: handle case when user is not logged in

          providers_by_slug = Providers.get_providers_mapped_by_slug()

          connected_providers_by_slug =
            Accounts.get_providers_with_stored_keys_by_slug(active_company.id)

          categories =
            WorkflowTemplates.get_workflow_template_categories(workflow_template.id)

          is_owner = workflow_template.created_by_id in [user_id, active_company.id]

          routes = [
            %{href: "/market", label: "Market", icon: "fa-solid:store"},
            %{
              href: "/market/#{workflow_template.slug}",
              label: workflow_template.name,
              active: true,
              icon: "fa-solid:magic"
            }
          ]

          socket
          |> assign(:page_title, workflow_template.name)
          |> assign(:workflow_template, workflow_template)
          |> assign(:categories, categories)
          |> assign(:providers_by_slug, providers_by_slug)
          |> assign(:connected_providers_by_slug, connected_providers_by_slug)
          |> assign(:is_owner, is_owner)
          |> assign(:routes, routes)

        _ ->
          socket
          |> Phoenix.LiveView.redirect(to: "/market")
          |> put_flash(:error, "Template doesn't exist.")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "react.delete_workflow_template",
        %{"workflow_template_id" => workflow_template_id} = _params,
        socket
      ) do
    workflow_template = WorkflowTemplates.get_workflow_template(workflow_template_id)

    socket =
      case workflow_template do
        %WorkflowTemplate{} ->
          WorkflowTemplates.delete_workflow_template(workflow_template)

          socket
          |> put_flash(:info, "Your workflow template has been deleted.")
          |> redirect(to: "/home")

        nil ->
          socket
          |> put_flash(:error, "The workflow template doesn't exist.")
          |> redirect(to: "/home")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.create_workflow_from_template",
        %{"workflow_template_id" => workflow_template_id},
        %{assigns: %{active_company: active_company}} = socket
      ) do
    socket =
      case WorkflowTemplates.create_workflow(active_company.id, workflow_template_id) do
        {:ok, workflow} ->
          workflow_dashboard_uri = "/workflows/#{workflow.id}/app-dashboard"

          socket
          |> put_flash(:info, "Created workflow from template.")
          |> redirect(to: workflow_dashboard_uri)

        {:error, _} ->
          socket
          |> put_flash(:error, "Failed to create workflow from template.")
      end

    {:noreply, socket}
  end
end
