# Import conveniences for testing
use Surface.LiveViewTest

# The default endpoint for testing
@endpoint Endpoint

alias <%= inspect module %>

test "renders <%= human %> component" do
  html =
    render_surface do
      <%= if Enum.empty?(slots) do %>~H"""
      <<%= inspect alias %>>
        Some Content
      </<%= inspect alias %>>
      """
      <% else %>~H"""
      <<%= inspect alias %>/>
      """<% end %>
    end

  assert html =~ """
        <div>
          <!-- <%= human %>  <%= for_slot_comment %>--><%= if Enum.empty?(slots) do %>
          Some Content<% end %>
        </div>
        """
end
