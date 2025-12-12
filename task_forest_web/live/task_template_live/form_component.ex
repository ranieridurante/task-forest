defmodule TaskForestWeb.TaskTemplateLive.FormComponent do
  use TaskForestWeb, :live_component

  alias TaskForest.Providers
  alias TaskForest.Tasks
  alias TaskForest.Tasks.TaskTemplate

  @impl true
  def render(assigns) do
    available_providers =
      Providers.get_providers()
      |> Enum.map(&{&1.name, &1.slug})

    access_type_options = [
      {"Creator", "creator"},
      {"Company", "company"},
      {"Public", "public"},
      {"Private", "private"}
    ]

    assigns =
      assigns
      |> assign(:available_providers, available_providers)
      |> assign(:access_type_options, access_type_options)

    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage task_template records in your database.</:subtitle>
      </.header>

      <.simple_form for={@form} id="task_template-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input type="checkbox" field={@form[:featured]} label="Featured" />
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:description]} label="Description" type="textarea" rows="2" />
        <.input
          field={@form[:provider_slug]}
          label="Provider Slug (to add a provider: https://app.plomb.ai/admin/providers)"
          type="select"
          options={@available_providers}
          prompt="Select a provider"
        />
        <.input field={@form[:config]} label="Config" type="textarea" rows="4" />
        <.input field={@form[:inputs_definition]} label="Inputs Definition" type="textarea" rows="4" />
        <.input field={@form[:outputs_definition]} label="Outputs Definition" type="textarea" rows="4" />
        <.input field={@form[:style]} label="Style" type="textarea" rows="4" />
        <.input field={@form[:creator_id]} label="Creator ID (leave empty for Plomb)" />
        <.input field={@form[:company_slug]} label="Company Slug (leave empty for Plomb)" />
        <.input
          field={@form[:access_type]}
          label="Access Type"
          type="select"
          options={@access_type_options}
          prompt="Select an access type"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Task template</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task_template: task_template} = assigns, socket) do
    changeset = Tasks.update_task_template_changeset(task_template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"_target" => ["task_template", key] = path, "task_template" => task_template_params},
        socket
      )
      when key in ["config", "inputs_definition", "outputs_definition", "style"] do
    try do
      _json_decode_attempt =
        task_template_params
        |> get_in(path)
        # NOTE: using a try block because Jason.decode raises
        |> Jason.decode()

      changeset =
        socket.assigns.task_template
        |> Tasks.update_task_template_changeset(task_template_params)
        |> Map.put(:action, :validate)

      {:noreply, assign_form(socket, changeset)}
    rescue
      _ -> {:noreply, socket}
    end
  end

  def handle_event("validate", %{"task_template" => task_template_params} = _params, socket) do
    changeset =
      socket.assigns.task_template
      |> Tasks.update_task_template_changeset(task_template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"task_template" => task_template_params}, socket) do
    save_task_template(socket, socket.assigns.action, task_template_params)
  end

  defp save_task_template(socket, :edit, task_template_params) do
    case Tasks.store_task_template(socket.assigns.task_template, task_template_params) do
      {:ok, task_template} ->
        notify_parent({:saved, task_template})

        {:noreply,
         socket
         |> put_flash(:info, "Task template updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_task_template(socket, :new, task_template_params) do
    case Tasks.store_task_template(%TaskTemplate{}, task_template_params) do
      {:ok, task_template} ->
        notify_parent({:saved, task_template})

        {:noreply,
         socket
         |> put_flash(:info, "Task template created successfully")
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
