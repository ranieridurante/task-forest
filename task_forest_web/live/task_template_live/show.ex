defmodule TaskForestWeb.TaskTemplateLive.Show do
  use TaskForestWeb, :live_view

  alias TaskForest.Tasks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:task_template, Tasks.get_task_template(id))}
  end

  defp page_title(:show), do: "Show Task template"
  defp page_title(:edit), do: "Edit Task template"
end
