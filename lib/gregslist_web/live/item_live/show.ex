defmodule GregslistWeb.ItemLive.Show do
  use GregslistWeb, :live_view

  alias Gregslist.Galleries

@impl true
def mount(_params, session, socket) do
  current_user = session["current_user"] # Retrieve the current user from the session

  socket =
    socket
    |> assign(:current_user, current_user)
    |> assign(:items, Galleries.list_items())

  {:ok, socket}
end



  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:item, Galleries.get_item!(id))}
  end

  defp page_title(:show), do: "Show Item"
  defp page_title(:edit), do: "Edit Item"
end
