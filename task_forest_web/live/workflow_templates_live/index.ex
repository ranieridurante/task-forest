defmodule TaskForestWeb.WorkflowTemplatesLive.Index do
  use TaskForestWeb, :live_view

  alias TaskForest.WorkflowTemplates
  alias TaskForest.WorkflowTemplates.WorkflowTemplate

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :workflow_templates_list, WorkflowTemplates.get_all_workflow_templates())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Workflow template")
    |> assign(:workflow_template, WorkflowTemplates.get_workflow_template(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Workflow templates")
    |> assign(:workflow_template, %WorkflowTemplate{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Workflow templates")
    |> assign(:workflow_templates, nil)
  end

  @impl true
  def handle_info(
        {TaskForestWeb.WorkflowTemplatesLive.FormComponent, {:saved, workflow_template}},
        socket
      ) do
    {:noreply, stream_insert(socket, :workflow_templates_list, workflow_template)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    workflow_template = WorkflowTemplates.get_workflow_template(id)
    {:ok, _} = Marketplace.delete_workflow_template(workflow_template)

    {:noreply, stream_delete(socket, :workflow_templates_list, workflow_template)}
  end
end
