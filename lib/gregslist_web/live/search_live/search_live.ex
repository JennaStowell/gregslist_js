defmodule GregslistWeb.SearchLive do
  use GregslistWeb, :live_view
  alias Gregslist.Galleries

  @impl true
  def mount(_params, _session, socket) do
    # Fetch all items initially, without any filters applied
    items = Galleries.list_items()
    {:ok, assign(socket, items: items, search: nil, category: nil, min_price: nil, max_price: nil, location: nil)}
  end

  @impl true
  @spec handle_event(<<_::48>>, map(), any()) :: {:noreply, any()}
  def handle_event("filter", %{"search" => search_term, "category" => category, "min_price" => min_price, "max_price" => max_price, "location" => location}, socket) do
    # Parse price inputs and log for debugging
    IO.inspect(min_price, label: "Min Price Input")
    IO.inspect(max_price, label: "Max Price Input")

    min_price = parse_price(min_price)
    max_price = parse_price(max_price)

    IO.inspect(min_price, label: "Parsed Min Price")
    IO.inspect(max_price, label: "Parsed Max Price")

    # Fetch and filter items based on category and price range
    items = Galleries.list_items()
           |> filter_by_name(search_term)
           |> filter_by_category(category)
           |> filter_by_price(min_price, max_price)
           |> filter_by_location(location)

    # Update socket with the filtered items and filter parameters
    {:noreply, assign(socket, items: items, search: search_term, category: category, min_price: min_price, max_price: max_price, location: location)}
  end

  # Helper function to parse price values
  defp parse_price(nil), do: nil
  defp parse_price(""), do: nil
  defp parse_price(price) do
    case Float.parse(price) do
      {float, _} -> float
      :error -> nil
    end
  end

  # Helper function to filter items by category
  defp filter_by_category(items, ""), do: items
  defp filter_by_category(items, category), do: Enum.filter(items, &(&1.categories == category))

  # Helper function to filter items by price range
  defp filter_by_price(items, nil, nil), do: items
  defp filter_by_price(items, min_price, nil) when not is_nil(min_price), do: Enum.filter(items, &(&1.price >= min_price))
  defp filter_by_price(items, nil, max_price) when not is_nil(max_price), do: Enum.filter(items, &(&1.price <= max_price))
  defp filter_by_price(items, min_price, max_price) when not is_nil(min_price) and not is_nil(max_price) do
    Enum.filter(items, &(&1.price >= min_price and &1.price <= max_price))
  end

  defp filter_by_location(items, ""), do: items
  defp filter_by_location(items, location), do: Enum.filter(items, &(&1.location == location))

  defp filter_by_name(items, ""), do: items
  defp filter_by_name(items, search_term) do
  Enum.filter(items, fn item ->
    String.contains?(String.downcase(item.item_name), String.downcase(search_term))
  end)
end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto py-8">
      <h1 class="text-4xl font-semibold text-center text-indigo-600 mb-8">Search Listings</h1>

      <!-- Name Search Input at the top -->
      <form phx-change="filter">
        <div class="mb-8">
          <div class="flex space-x-4 justify-center">
            <div class="w-full md:w-1/2">
              <label for="search" class="text-gray-700 sr-only">Search by Name</label>
              <input type="text" id="search" name="search" value={@search || ""} placeholder="Search by name..." class="border p-2 rounded w-full" />
            </div>
          </div>
        </div>

        <!-- Filters Section -->
        <div class="space-y-4 mb-8">
          <div class="flex space-x-4">
            <!-- Category Filter Dropdown -->
            <div>
              <label for="category" class="text-gray-700">Category</label>
              <select id="category" name="category" class="border p-2 rounded">
                <option value="">All Categories</option>
                <option value="technology">Technology</option>
                <option value="furniture">Furniture</option>
                <option value="vehicles">Vehicles</option>
                <option value="clothes">Clothing</option>
                <option value="business">Business</option>
                <option value="other">Other</option>
              </select>
            </div>

            <!-- Min Price Input -->
            <div>
              <label for="min_price" class="text-gray-700">Min Price</label>
              <input type="number" id="min_price" name="min_price" value={@min_price || ""} class="border p-2 rounded" placeholder="Min Price" />
            </div>

            <!-- Max Price Input -->
            <div>
              <label for="max_price" class="text-gray-700">Max Price</label>
              <input type="number" id="max_price" name="max_price" value={@max_price || ""} class="border p-2 rounded" placeholder="Max Price" />
            </div>

            <!-- Location Filter Input -->
            <div>
              <label for="location" class="text-gray-700">Location</label>
              <input type="text" id="location" name="location" value={@location || ""} class="border p-2 rounded" placeholder="Location" />
            </div>
          </div>
        </div>
      </form>

      <!-- Search Results -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for item <- @items do %>
          <div class="bg-white p-4 rounded shadow">
            <%= if item.images !=nil && length(item.images) > 0 do %>
              <img src={hd(item.images).dataUrl} />
            <% end %>
            <h3 class="font-semibold text-xl text-indigo-600"><%= item.item_name %></h3>
            <p class="text-gray-600"><%= item.desc %></p>
            <p class="text-indigo-700 font-semibold">$<%= item.price %></p>
            <p class="text-gray-500">Category: <%= item.categories %></p>
            <p class="text-gray-500">Location: <%= item.location %></p>
          </div>
        <% end %>
      </div>
    </div>
    """
end
end
