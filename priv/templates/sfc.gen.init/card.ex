defmodule <%= inspect module %> do
  @moduledoc """
  A simple Card component with three slots: header, body, footer.
  See [here](https://surface-ui.org/slots#named-slots) for a similar
  example & usage.
  """

  use Surface.Component

  @doc "Css classes for the card component. Default [\"card\"]"
  prop class, :css_class, default: ["card"]

  @doc "Css classes for the card header. Default [\"card-header\"]"
  prop header_class, :css_class, default: ["card-header"]

  @doc "Css classes for the card footer. Default [\"card-footer\"]"
  prop footer_class, :css_class, default: ["card-footer"]

  @doc "The header"
  slot header

  @doc "The footer"
  slot footer

  @doc "The main content"
  slot default
<%= unless template do %>

  def render(assigns) do
    ~H"""
    <div class={ @class }>
      <header class={ @header_class }>
        <p class="card-header-title">
          <#slot name="header"/>
        </p>
      </header>
      <div class="card-content">
        <div class="content">
          <#slot/>
        </div>
      </div>
      <footer class={ @footer_class }>
        <#slot name="footer"/>
      </footer>
    </div>
    """
  end
<% end %>end
