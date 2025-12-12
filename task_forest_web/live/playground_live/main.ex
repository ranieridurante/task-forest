defmodule TaskForestWeb.PlaygroundLive.Main do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Workflows

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(
        %{"workflow_id" => workflow_id},
        _uri,
        %{assigns: %{active_company: _active_company} = _assigns} = socket
      ) do
    workflow = Workflows.get_workflow_by_id(workflow_id)

    routes =
      [
        %{href: "/home", label: "Home", icon: "mingcute:home-7-fill"},
        %{
          href: "/workflows/#{workflow.id}",
          label: workflow.name,
          icon: "streamline-ultimate:workflow-exit-door-bold"
        },
        %{
          href: "/workflows/#{workflow_id}/playground",
          label: "Workflow Playground",
          active: true,
          icon: "grommet-icons:test"
        }
      ]

    socket =
      socket
      |> assign(:page_title, "Workflow Playground: #{workflow.name}")
      |> assign(:workflow, workflow)
      |> assign(:routes, routes)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "react.execute_workflow",
        %{"workflow_id" => workflow_id, "inputs" => inputs} = _params,
        socket
      ) do
    pid = self()

    socket =
      case Workflows.execute_workflow(workflow_id, inputs, %{notify_to: pid}) do
        {:ok, execution_id} ->
          push_event(socket, "server.workflow_update", %{
            execution_id: execution_id,
            status: "started"
          })

        {:error, :not_enough_credits} ->
          put_flash(socket, :error, "Not enough credits to execute the workflow")

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("react.cancel_execution", %{"execution_id" => execution_id}, socket) do
    outputs = %{
      error: "Execution cancelled by user"
    }

    socket =
      case Workflows.mark_execution_as_cancelled(execution_id, outputs) do
        {:ok, _} ->
          push_event(socket, "server.workflow_update", %{
            execution_id: execution_id,
            status: "cancelled",
            outputs: outputs
          })

        {:error, _} ->
          put_flash(socket, :error, "Failed to cancel execution")
      end

    {:noreply, socket}
  end
end
