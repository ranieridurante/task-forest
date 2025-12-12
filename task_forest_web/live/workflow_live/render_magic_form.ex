defmodule TaskForestWeb.WorkflowLive.RenderMagicForm do
  use TaskForestWeb, :live_view

  alias TaskForest.Workflows
  alias TaskForest.Workflows.MagicForm
  alias TaskForestWeb.Layouts

  @impl true
  def mount(
        %{"magic_form_id" => magic_form_id},
        _session,
        %{assigns: %{live_action: :editor}} = socket
      ) do
    magic_form = Workflows.get_magic_form_by_id(magic_form_id)

    workflow = Workflows.get_workflow_by_id(magic_form.workflow_id)

    routes = [
      %{href: "/home", label: "Home", icon: "mingcute:home-7-fill"},
      %{href: "/workflows/#{workflow.id}", label: workflow.name},
      %{
        href: "/workflows/#{workflow.id}/magic-forms",
        label: "Magic Forms",
        icon: "fluent:form-sparkle-20-filled"
      },
      %{href: "/magic-forms/#{magic_form.id}/editor", label: magic_form.name, active: true}
    ]

    socket =
      socket
      |> assign(:magic_form, magic_form)
      |> assign(:user_request, magic_form.user_request)
      |> assign(:routes, routes)
      |> assign(:generating_form, false)

    {:ok, socket, layout: {Layouts, :editor}}
  end

  def mount(%{"magic_form_id" => magic_form_id}, _session, socket) do
    magic_form = Workflows.get_magic_form_by_id(magic_form_id)

    if connected?(socket) do
      register_pageview(magic_form_id)
    end

    socket =
      socket
      |> assign(:magic_form, magic_form)
      |> assign(:generating_form, false)

    {:ok, socket, layout: {Layouts, :magic_form}}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit_magic_form",
        workflow_inputs,
        %{assigns: %{magic_form: magic_form}} = socket
      ) do
    socket =
      case Workflows.execute_workflow(magic_form.workflow_id, workflow_inputs) do
        {:ok, _execution_id} ->
          register_submission(magic_form.id)

          socket
          |> put_flash(:info, "Submission received. Executing workflow.")

        {:error, _error_msg} ->
          socket
          |> put_flash(:error, "There was an error executing the workflow.")
      end

    {:noreply, socket}
  end

  def handle_event(
        "generate_magic_form",
        %{"user_request" => user_request} = _params,
        %{assigns: %{magic_form: magic_form}} = socket
      ) do
    pid = self()

    socket =
      case Workflows.generate_magic_form_code(user_request, magic_form, %{notify_to: pid}) do
        {:ok, _execution_id} ->
          socket
          |> put_flash(:info, "Generated a new magic form.")
          |> assign(:magic_form, magic_form)
          |> assign(:user_request, user_request)
          |> assign(:generating_form, true)

        {:error, _error_msg} ->
          socket
          |> put_flash(:error, "There was an error generating your magic form.")
          |> assign(:user_request, user_request)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:workflow_completed, %{execution_id: execution_id}},
        %{assigns: %{magic_form: magic_form, user_request: user_request}} = socket
      ) do
    socket =
      with {:ok, execution} <- Workflows.get_execution_by_id(execution_id),
           params <- %{user_request: user_request, html: execution.outputs["magic_form_code"]},
           {:ok, magic_form} <- Workflows.update_magic_form(magic_form, params) do
        socket
        |> put_flash(:info, "Your new magic form is ready.")
        |> assign(:magic_form, magic_form)
        |> assign(:generating_form, false)
      else
        _ ->
          socket
          |> put_flash(:error, "There was an error saving your new magic form.")
      end

    {:noreply, socket}
  end

  def handle_info({:workflow_cancelled, _data}, socket) do
    socket =
      socket
      |> put_flash(:error, "The generation of your magic form was cancelled.")
      |> assign(:generating_form, false)

    {:noreply, socket}
  end

  def handle_info({:task_error, _data}, socket) do
    socket =
      socket
      |> put_flash(:error, "There was an error generating your magic form.")
      |> assign(:generating_form, false)

    {:noreply, socket}
  end

  defp register_submission(magic_form_id) do
    Elixir.Task.start(fn -> Workflows.increase_magic_form_submissions(magic_form_id) end)
  end

  defp register_pageview(magic_form_id) do
    Elixir.Task.start(fn -> Workflows.increase_magic_form_views(magic_form_id) end)
  end
end
