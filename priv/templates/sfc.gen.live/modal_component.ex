defmodule <%= inspect context.web_module %>.Components.Modal do
  use <%= inspect context.web_module %>, :surface_component

  alias Surface.Components.LivePatch
  @doc "whether to show a close (X) button"
  prop show_close, :boolean, default: true

  @doc "url to update to when the modal is closed"
  prop return_to, :string

  @doc "optional title for the modal"
  prop title, :string

  @doc "the content of the module"
  slot default, required: true


  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="phx-modal"
      capture-click="close"
      window-keydown="close"
      key="escape"
      phx-page-loading
    >

      <div class="phx-modal-content">
        <LivePatch :if={@show_close} to={@return_to} class="phx-modal-close">
          &times
        </LivePatch>
        <h2 :if={@title} class="text-sm font-display">
          {@title}
        </h2>
        <#slot/>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
