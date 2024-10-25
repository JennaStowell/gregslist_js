defmodule GregslistWeb.ItemLive.FormComponent do
  use GregslistWeb, :live_component




  alias Gregslist.Galleries
  alias Gregslist.Galleries
  

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage item records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:item_name]} type="text" label="Item name" />
        <.input field={@form[:desc]} type="text" label="Desc" />
        <.input field={@form[:price]} type="number" label="Price" step="any" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:art_image]} type="file" label="Item Picture" />
        <.input field={@form[:user_id]} type="hidden"  value={@current_user.id} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Item</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end


@impl true
  def mount(_params, %{"current_user" => current_user} = _session, socket) do
  socket = 
    socket 
    |> assign(:uploads, %{})
    |> allow_upload(:art_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
    |> assign(:items, Galleries.list_items())
    |> assign(:current_user, current_user)

  {:ok, socket}
end

  @impl true
  def update(%{item: item} = assigns, socket) do
  _changeset = Galleries.change_item(item)
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Galleries.change_item(item))
      end)}
end


  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset = Galleries.change_item(socket.assigns.item, item_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  defp save_item(socket, :edit, item_params) do
    case Galleries.update_item(socket.assigns.item, item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_item(socket, :new, item_params) do
    case Galleries.create_item(item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
