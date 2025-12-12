defmodule TaskForestWeb.TaskTemplateLive.Index do
  use TaskForestWeb, :live_view

  alias TaskForest.Tasks
  alias TaskForest.Tasks.TaskTemplate

  @page_size 200

  @impl true
  def mount(_params, _session, socket) do
    initial_page = 1

    %{data: data, count: count, providers: providers} = Tasks.get_task_templates()

    total_pages = get_total_pages(count)

    socket =
      socket
      |> stream(:task_templates, data)
      |> assign(:current_page, initial_page)
      |> assign(:total_pages, total_pages)
      |> assign(:providers, providers)
      |> assign(:selected_provider, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Task template")
    |> assign(:task_template, Tasks.get_task_template(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Task template")
    |> assign(:task_template, %TaskTemplate{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Task templates")
    |> assign(:task_template, nil)
  end

  @impl true
  def handle_info({TaskForestWeb.TaskTemplateLive.FormComponent, {:saved, task_template}}, socket) do
    {:noreply, stream_insert(socket, :task_templates, task_template)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task_template = Tasks.get_task_template(id)
    {:ok, _} = Tasks.delete_task_template(task_template)

    {:noreply, stream_delete(socket, :task_templates, task_template)}
  end

  def handle_event("next_page", _params, %{assigns: %{current_page: current_page}} = socket) do
    new_page = current_page + 1

    socket = load_task_templates(new_page, socket)

    {:noreply, socket}
  end

  def handle_event("previous_page", _params, %{assigns: %{current_page: current_page}} = socket) do
    new_page = current_page - 1

    socket = load_task_templates(new_page, socket)

    {:noreply, socket}
  end

  def handle_event("filter_by_provider", %{"provider" => provider_slug}, socket) do
    new_page = 1

    socket = load_task_templates(new_page, socket, provider_slug)

    {:noreply, socket}
  end

  defp get_total_pages(total_count) do
    (total_count / @page_size)
    |> Float.ceil()
    |> trunc()
  end

  defp load_task_templates(
         requested_page,
         %{assigns: %{selected_provider: selected_provider}} = socket,
         provider_slug \\ nil
       ) do
    opts = [
      page: requested_page,
      page_size: @page_size
    ]

    selected_provider = provider_slug || selected_provider

    opts =
      if selected_provider do
        opts ++ [provider: selected_provider]
      else
        opts
      end

    %{data: data, count: count} =
      Tasks.get_task_templates(opts)

    total_pages = get_total_pages(count)

    socket
    |> stream(:task_templates, data, reset: true)
    |> assign(:current_page, requested_page)
    |> assign(:total_pages, total_pages)
    |> assign(:selected_provider, selected_provider)
  end
end
