defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Live.FormComponent do
  use <%= inspect context.web_module %>, :surface_component

  alias <%= inspect context.module %>
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label, ErrorTag, Submit, <%= form_imports %>}

  @doc "The instance of <%= schema.alias %> being edited/created"
  prop <%= schema.singular %>, :map, required: true

  @doc "The action (:new / :edit) for the form"
  prop action, :atom, values: [:new, :edit], required: true

  @doc "The url to redirect to upon a successful submit"
  prop return_to, :string, required: true

  @impl true
  def update(%{<%= schema.singular %>: <%= schema.singular %>} = assigns, socket) do
    changeset = <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"<%= schema.singular %>" => <%= schema.singular %>_params}, socket) do
    changeset =
      socket.assigns.<%= schema.singular %>
      |> <%= inspect context.alias %>.change_<%= schema.singular %>(<%= schema.singular %>_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"<%= schema.singular %>" => <%= schema.singular %>_params}, socket) do
    save_<%= schema.singular %>(socket, socket.assigns.action, <%= schema.singular %>_params)
  end

  defp save_<%= schema.singular %>(socket, :edit, <%= schema.singular %>_params) do
    case <%= inspect context.alias %>.update_<%= schema.singular %>(socket.assigns.<%= schema.singular %>, <%= schema.singular %>_params) do
      {:ok, _<%= schema.singular %>} ->
        {:noreply,
         socket
         |> put_flash(:info, "<%= schema.human_singular %> updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_<%= schema.singular %>(socket, :new, <%= schema.singular %>_params) do
    case <%= inspect context.alias %>.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      {:ok, _<%= schema.singular %>} ->
        {:noreply,
         socket
         |> put_flash(:info, "<%= schema.human_singular %> created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
