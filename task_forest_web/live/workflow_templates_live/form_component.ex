defmodule TaskForestWeb.WorkflowTemplatesLive.FormComponent do
  use TaskForestWeb, :live_component

  alias TaskForest.WorkflowTemplates
  alias TaskForest.WorkflowTemplates.WorkflowTemplate

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage workflow_template records in your database.</:subtitle>
      </.header>

      <.simple_form for={@form} id="workflow_template-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <:actions>
          <.button phx-disable-with="Saving...">Save Workflow templates</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{workflow_template: workflow_template} = assigns, socket) do
    changeset = WorkflowTemplates.update_workflow_template_changeset(workflow_template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"workflow_template" => workflow_template_params}, socket) do
    changeset =
      socket.assigns.workflow_template
      |> WorkflowTemplates.update_workflow_template_changeset(workflow_template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"workflow_template" => workflow_template_params}, socket) do
    save_workflow_template(socket, socket.assigns.action, workflow_template_params)
  end

  defp save_workflow_template(socket, :edit, workflow_template_params) do
    case WorkflowTemplates.store_workflow_template(
           socket.assigns.workflow_template,
           workflow_template_params
         ) do
      {:ok, workflow_template} ->
        notify_parent({:saved, workflow_template})

        {:noreply,
         socket
         |> put_flash(:info, "Workflow templates updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_workflow_template(socket, :new, workflow_template_params) do
    case WorkflowTemplates.store_workflow_template(%WorkflowTemplate{}, workflow_template_params) do
      {:ok, workflow_template} ->
        notify_parent({:saved, workflow_template})

        {:noreply,
         socket
         |> put_flash(:info, "Workflow templates created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
