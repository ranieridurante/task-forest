defmodule TaskForestWeb.WorkflowTemplatesLive.Show do
  use TaskForestWeb, :live_view

  alias TaskForest.WorkflowTemplates

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:workflow_template, WorkflowTemplates.get_workflow_template(id))}
  end

  defp page_title(:show), do: "Show Workflow template"
  defp page_title(:edit), do: "Edit Workflow template"
end
