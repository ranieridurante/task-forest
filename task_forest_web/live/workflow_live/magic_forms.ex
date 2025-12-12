defmodule TaskForestWeb.WorkflowLive.MagicForms do
  use TaskForestWeb, :live_view

  alias TaskForest.Workflows
  alias TaskForest.Workflows.MagicForm

  @impl true
  def mount(%{"workflow_id" => workflow_id}, _session, socket) do
    magic_forms = Workflows.get_workflow_magic_forms(workflow_id)

    socket =
      socket
      |> assign(:magic_forms, magic_forms)
      |> assign(:workflow_id, workflow_id)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("react.delete_magic_form", %{"magic_form_id" => magic_form_id}, socket) do
    case Workflows.delete_magic_form(magic_form_id) do
      {:ok, _} ->
        magic_forms = Enum.reject(socket.assigns.magic_forms, fn mf -> mf.id == magic_form_id end)

        socket =
          socket
          |> assign(:magic_forms, magic_forms)
          |> put_flash(:info, "Magic form deleted successfully.")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete magic form.")}
    end
  end

  def handle_event("react.create_magic_form", _, %{assigns: %{workflow_id: workflow_id}} = socket) do
    socket =
      case Workflows.create_magic_form(workflow_id) do
        {:ok, magic_form} ->
          editor_uri = "/magic-forms/#{magic_form.id}/editor"

          socket
          |> put_flash(:info, "Starting a new magic form.")
          |> redirect(to: editor_uri)

        {:error, _} ->
          socket
          |> put_flash(:error, "There was an error creating a new magic form.")
      end

    {:noreply, socket}
  end
end
