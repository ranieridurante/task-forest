defmodule TaskForestWeb.ProviderLive.FormComponent do
  use TaskForestWeb, :live_component

  alias TaskForest.Providers
  alias TaskForest.Providers.Provider

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage provider records in your database.</:subtitle>
      </.header>

      <.simple_form for={@form} id="provider-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:slug]} label="Slug (must be unique)" />
        <.input field={@form[:website]} label="Website" />
        <.input
          field={@form[:logo]}
          label="Logo URL (use https://logo.clearbit.com/<website.com> or https://img.logo.dev/<website.com>?token=pk_FTxTPNXSRt28mcTgy0fTcQ)"
        />
        <.input field={@form[:keys]} label="Keys" type="textarea" rows="4" />
        <.input field={@form[:instructions]} label="Instructions" type="textarea" rows="10" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Provider</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{provider: provider} = assigns, socket) do
    changeset = Providers.update_provider_changeset(provider)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"_target" => ["provider", "keys"] = path, "provider" => provider_params},
        socket
      ) do
    try do
      _json_decode_attemps =
        provider_params
        |> get_in(path)
        # NOTE: using a try block because Jason.decode raises
        |> Jason.decode()

      changeset =
        socket.assigns.provider
        |> Providers.update_provider_changeset(provider_params)
        |> Map.put(:action, :validate)

      {:noreply, assign_form(socket, changeset)}
    rescue
      _ -> {:noreply, socket}
    end
  end

  def handle_event("validate", %{"provider" => provider_params}, socket) do
    changeset =
      socket.assigns.provider
      |> Providers.update_provider_changeset(provider_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"provider" => provider_params}, socket) do
    save_provider(socket, socket.assigns.action, provider_params)
  end

  defp save_provider(socket, :edit, provider_params) do
    case Providers.store_provider(socket.assigns.provider, provider_params) do
      {:ok, provider} ->
        notify_parent({:saved, provider})

        {:noreply,
         socket
         |> put_flash(:info, "Provider updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_provider(socket, :new, provider_params) do
    case Providers.store_provider(%Provider{}, provider_params) do
      {:ok, provider} ->
        notify_parent({:saved, provider})

        {:noreply,
         socket
         |> put_flash(:info, "Provider created successfully")
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
