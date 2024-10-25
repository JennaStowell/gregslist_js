defmodule GregslistWeb.ItemLive.Index do
  use GregslistWeb, :live_view

  alias Gregslist.Repo
  alias Gregslist.Galleries
  alias Gregslist.Galleries.Item
  alias Gregslist.Galleries
  
@impl true
  def mount(params, session, socket) do
    current_user = session["current_user"]
    
    socket =
      socket
      |> assign(:current_user, current_user)

      |> allow_upload(:art_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)  # Allow image uploads
      |> stream(:items, Galleries.list_items())  # Stream existing items

    {:ok, socket}
  end



  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:item, Galleries.get_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Items")
    |> assign(:item, nil)
  end

  @impl true
  def handle_info({GregslistWeb.ItemLive.FormComponent, {:saved, item}}, socket) do
    {:noreply, stream_insert(socket, :items, item)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Galleries.get_item!(id)
    {:ok, _} = Galleries.delete_item(item)

    {:noreply, stream_delete(socket, :items, item)}
  end

  def create_item(attrs, user) do
  %Item{}
  |> Item.changeset(Map.put(attrs, "user_id", user.id))
  |> Repo.insert()
end


def create_item(%{"item" => item_params}, socket) do
  # Save the uploaded file to a directory and get the file path
  uploaded_files = consume_uploaded_entries(socket, :art_image, fn %{path: path}, entry ->
    # Define a location to store the image
    file_dest = Path.join("priv/static/images", entry.client_name)

    # Copy the uploaded file to the destination
    File.cp!(path, file_dest)

    # Return the relative path to be saved in the database
    {:ok, file_dest}
  end)

  # Use the file path in the item params if an image was uploaded
  updated_item_params = 
    case uploaded_files do
      [file_path] -> Map.put(item_params, "art_image", file_path)
      _ -> item_params
    end

  # Insert the item into the database
  %Item{}
  |> Item.changeset(updated_item_params)
  |> Repo.insert()
end

end
