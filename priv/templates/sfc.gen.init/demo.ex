defmodule <%= inspect module %> do
  @moduledoc """
  Document <%= inspect module %> here.
  """
  use Surface.Component
<%= for {name, prop} <- props do %>
  @doc "property <%= name %>"
  prop <%= name %>, <%= inspect prop.type %><%= Enum.join(prop.opts, ", ") %>
<% end %><%= for slot <- slots do %>
  @doc "property <%= slot.name %>"
  slot <%= slot.name %><%= Enum.join(slot.opts, ", ") %>
<% end %><%= unless template do %>

  def render(assigns) do
    ~H"""
    <!-- <%= human %> --><%= for slot <- slots do %>

    <slot<%= slot.attr_name %><%= slot.attr_props %>/><% end %>
    """
  end
<% end %>end
